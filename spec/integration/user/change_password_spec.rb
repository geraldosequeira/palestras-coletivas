require "spec_helper"

describe "Change password" do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:other_user) }

  context "with valid data" do
    before do
      login_as user
      visit root_path
      click_link "Trocar senha"

      fill_in "Sua senha", :with => "newpassword"
      fill_in "Confirme sua senha", :with => "newpassword"

      click_button "Atualizar dados"
    end

    it "redirects to the user show page" do
      expect(current_path).to match(%r[/users/\w+])
    end

    it "displays success message" do
      expect(page).to have_content("Seus dados foram atualizados!")
    end
  end

  context "with invalid data" do
    before do
      login_as user
      visit root_path
      click_link "Trocar senha"

      fill_in "Sua senha", :with => "newpassword"
      fill_in "Confirme sua senha", :with => "otherpassword"

      click_button "Atualizar dados"
    end

    it "renders form page" do
      expect(current_path).to eql(edit_user_path(user))
    end

    it "displays error messages" do
      expect(page).to have_content("Verifique o formulário antes de continuar:")
    end
  end

  context "when the current user is not user" do
    before do
      login_as(other_user)
      visit change_password_path(user)
    end

    it "redirects to the talks page" do
      expect(current_path).to eql(talks_path)
    end

    it "displays error messages" do
      expect(page).to have_content("Você não tem permissão para acessar esta página.")
    end
  end
end