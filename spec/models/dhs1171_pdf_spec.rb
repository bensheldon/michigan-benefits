require "rails_helper"

RSpec.describe Dhs1171Pdf do
  describe "#save" do
    it "saves the client info" do
      mailing_address = create(:mailing_address)
      residential_address = create(:address)
      member = create(:member)
      snap_application = create(
        :snap_application,
        addresses: [mailing_address, residential_address],
        members: [member],
      )
      client_data = {
        applying_for_food_assistance: "Yes",
        phone_number: snap_application.phone_number,
        mailing_address_street_address:
        snap_application.mailing_address.street_address,
        mailing_address_city: snap_application.mailing_address.city,
        mailing_address_county: snap_application.mailing_address.county,
        mailing_address_state: snap_application.mailing_address.state,
        mailing_address_zip: snap_application.mailing_address.zip,
        residential_address_street_address:
        snap_application.residential_address.street_address,
        residential_address_city: snap_application.residential_address.city,
        residential_address_county: snap_application.residential_address.county,
        residential_address_state: snap_application.residential_address.state,
        residential_address_zip: snap_application.mailing_address.zip,
        email: snap_application.email,
        signature: snap_application.signature,
        signature_date: snap_application.signed_at_est,
        primary_member_birthday: member.birthday.strftime("%m/%d/%Y"),
        primary_member_marital_status_married: nil,
        primary_member_marital_status_never_married: nil,
        primary_member_marital_status_divorced: nil,
        primary_member_marital_status_widowed: "Yes",
        primary_member_marital_status_separated: nil,
        primary_member_citizen_yes: nil,
        primary_member_citizen_no: "Yes",
        primary_member_new_mom_yes: nil,
        primary_member_new_mom_no: "Yes",
        primary_member_in_college_yes: nil,
        primary_member_in_college_no: "Yes",
        primary_member_relationship: "",
        primary_member_sex_male: nil,
        primary_member_sex_female: "Yes",
        primary_member_full_name: member.full_name,
      }

      file = Dhs1171Pdf.new(snap_application: snap_application).completed_file

      result = filled_in_values(file: file.path)
      client_data.each do |field, entered_data|
        expect(result[field.to_s].to_s).to eq entered_data.to_s
      end
    end

    context "multiple household members" do
      it "returns attributes for each member" do
        first_member = create(:member)
        second_member = create(:member)
        snap_application =
          create(:snap_application, members: [first_member, second_member])

        file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
        result = filled_in_values(file: file.path)

        expect(result["primary_member_full_name"]).to eq(
          first_member.full_name,
        )
        expect(result["second_member_full_name"]).to eq(
          second_member.full_name,
        )
      end
    end

    context "employed and self employed household members" do
      it "returns attributes for each member" do
        employed_member = create(:member, employment_status: "employed")
        self_employed_member =
          create(:member, employment_status: "self_employed")
        snap_application = create(
          :snap_application,
          members: [self_employed_member, employed_member],
        )

        file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
        result = filled_in_values(file: file.path)

        expect(result["first_employed_full_name"]).to eq(
          employed_member.full_name,
        )
        expect(result["first_self_employed_full_name"]).to eq(
          self_employed_member.full_name,
        )
      end
    end

    context "additional income sources" do
      it "adds the additional income source fields" do
        snap_application = create(
          :snap_application,
          :with_member,
          additional_income: ["child_support", "pension"],
          income_child_support: 100,
          income_pension: 50,
        )

        file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
        result = filled_in_values(file: file.path)

        expect(result["first_additional_income_type"]).to eq(
          "Child Support",
        )
        expect(result["first_additional_income_amount"]).to eq(
          "100",
        )
        expect(result["second_additional_income_type"]).to eq(
          "Pension",
        )
        expect(result["second_additional_income_amount"]).to eq(
          "50",
        )
      end
    end

    it "prepends a cover sheet" do
      snap_application = create(:snap_application, :with_member)
      original_length = PDF::Reader.new(Dhs1171Pdf::SOURCE_PDF).page_count

      file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
      new_pdf = PDF::Reader.new(file.path)

      expect(new_pdf.page_count).to eq(original_length + 1)
    end

    it "appends pages if there are more than 6 household members" do
      members = create_list(:member, 8)
      snap_application = create(:snap_application, members: members)
      original_length = PDF::Reader.new(Dhs1171Pdf::SOURCE_PDF).page_count

      file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
      new_pdf = PDF::Reader.new(file.path)

      expect(new_pdf.page_count).to eq(original_length + 2)
    end

    it "appends pages if there are more than 2 employed members" do
      members = create_list(:member, 3, employment_status: "employed")
      snap_application = create(:snap_application, members: members)
      original_length = PDF::Reader.new(Dhs1171Pdf::SOURCE_PDF).page_count

      file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
      new_pdf = PDF::Reader.new(file.path)

      expect(new_pdf.page_count).to eq(original_length + 2)
    end

    it "appends pages if there are more than 2 self-employed members" do
      members = create_list(:member, 3, employment_status: "self_employed")
      snap_application = create(:snap_application, members: members)
      original_length = PDF::Reader.new(Dhs1171Pdf::SOURCE_PDF).page_count

      file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
      new_pdf = PDF::Reader.new(file.path)

      expect(new_pdf.page_count).to eq(original_length + 2)
    end

    it "appends pages if there are verification documents" do
      document_path = "http://example.com"
      verification_document = double
      allow(verification_document).to receive(:file).and_return(
        File.open("spec/fixtures/test_pdf.pdf"),
      )
      snap_application =
        create(:snap_application, :with_member, documents: [document_path])
      allow(VerificationDocument).to receive(:new).with(
        url: document_path,
        snap_application: snap_application,
      ).and_return(verification_document)
      original_length = PDF::Reader.new(Dhs1171Pdf::SOURCE_PDF).page_count

      file = Dhs1171Pdf.new(snap_application: snap_application).completed_file
      new_pdf = PDF::Reader.new(file.path)

      expect(new_pdf.page_count).to eq(original_length + 2)
    end

    it "returns the tempfile" do
      snap_application = create(:snap_application, :with_member)

      file = Dhs1171Pdf.new(snap_application: snap_application).completed_file

      expect(file).to be_a_kind_of(Tempfile)
    end
  end

  def filled_in_values(file:)
    filled_in_fields = pdftk.get_fields(file)

    filled_in_fields.each_with_object({}) do |field, hash|
      hash[field.name] = field.value
    end
  end

  def pdftk
    @_pdftk ||= PdfForms.new
  end
end
