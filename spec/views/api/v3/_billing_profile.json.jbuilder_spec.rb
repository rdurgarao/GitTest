require 'spec_helper'

RSpec.describe 'api/v3/_billing_profile', :caching, type: :view do
  let(:profile) do
    create(:billing_info)
  end

  it 'renders profile' do
    render 'api/v3/billing_profile', profile: profile
    expect(JSON.parse(rendered)).to eq(
      'id' => profile.id,
      'address' => profile.address,
      'address_name' => profile.address_name,
      'city' => profile.city,
      'name' => profile.name,
      'phone' => profile.phone,
      'state' => profile.state,
      'dist' => profile.dist,
      'dist_code' => profile.dist_code,
      'province_id' => profile.province_id,
      'province' => profile.province_name,
      'province_name' => profile.province_name,
      'zip_code' => profile.zip_code,
      'country' => profile.country,
      'created_at' => profile.created_at.as_json,
      'updated_at' => profile.updated_at.as_json,
      'country_code' => profile.country_code,
      'shipping_way' => profile.shipping_way,
      'email' => profile.email
    )
  end
end
