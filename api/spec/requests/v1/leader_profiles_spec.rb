# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::LeaderProfiles', type: :request do
  let(:profile) do
    create(:completed_leader_profile, user: create(:user_authed))
  end
  let(:applicant) { profile.user }
  let(:application) { profile.new_club_application }

  let(:auth_headers) { { 'Authorization': "Bearer #{applicant.auth_token}" } }

  before { application.update_attributes(point_of_contact: applicant) }

  describe 'GET /v1/leader_profiles/:id' do
    it 'requires authentication' do
      get "/v1/leader_profiles/#{profile.id}"
      expect(response.status).to eq(401)
    end

    it 'returns the requested leader profile' do
      get "/v1/leader_profiles/#{profile.id}", headers: auth_headers

      expect(response.status).to eq(200)
      expect(json).to include('leader_name')
    end

    it "refuses to return someone else's leader profile" do
      other_profile = create(:leader_profile)

      get "/v1/leader_profiles/#{other_profile.id}", headers: auth_headers

      expect(response.status).to eq(403)
      expect(json).to include('error' => 'access denied')
    end

    it "404s if profile doesn't exist" do
      get "/v1/leader_profiles/#{profile.id + 1}", headers: auth_headers

      expect(response.status).to eq(404)
      expect(json).to include('error' => 'not found')
    end
  end

  describe 'PATCH /v1/leader_profile/id' do
    it 'requires authentication' do
      patch "/v1/leader_profiles/#{profile.id}"
      expect(response.status).to eq(401)
    end

    it 'updates the given fields' do
      patch "/v1/leader_profiles/#{profile.id}",
            headers: auth_headers,
            params: {
              leader_name: 'John Doe',
              leader_email: 'john@johndoe.com'
            }

      expect(response.status).to eq(200)
      expect(json).to include(
        'leader_name' => 'John Doe',
        'leader_email' => 'john@johndoe.com'
      )
    end

    it 'fails to update fields after application is submitted' do
      post "/v1/new_club_applications/#{application.id}/submit",
           headers: auth_headers

      patch "/v1/leader_profiles/#{profile.id}",
            headers: auth_headers,
            params: { leader_name: 'Jane Doe' }

      expect(response.status).to eq(422)
      expect(
        json['errors']['base']
      ).to include('cannot edit leader profile after submit')
    end

    it "refuses to update someone else's profile" do
      other_profile = create(:leader_profile)

      patch "/v1/leader_profiles/#{other_profile.id}",
            headers: auth_headers,
            params: {
              leader_name: 'John Doe'
            }

      expect(response.status).to eq(403)
      expect(json).to include('error' => 'access denied')
    end

    it "404s if profile doesn't exist" do
      patch "/v1/leader_profiles/#{profile.id + 1}",
            headers: auth_headers,
            params: {
              leader_name: 'John Doe'
            }

      expect(response.status).to eq(404)
      expect(json).to include('error' => 'not found')
    end
  end
end
