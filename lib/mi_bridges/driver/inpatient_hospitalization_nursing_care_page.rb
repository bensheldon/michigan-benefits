# frozen_string_literal: true

module MiBridges
  class Driver
    class InpatientHospitalizationNursingCarePage < ClickNextPage
      TITLE = /(.*)'s Inpatient Hospitalization\/Nursing Care/
    end
  end
end
