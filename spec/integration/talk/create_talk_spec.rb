require "spec_helper"

describe "Create talk", :type => :request, :js => true do
  let!(:user)         { create(:user, :paul) }
  let!(:invited_user) { create(:user, :luis, name: "Luis XIV", username: "@username_luis") }
  let!(:other_user)   { create(:user, :billy, name: "Billy Boy", username: "@username_billy") }
  let!(:talk)         { create(:talk, :users => [ user ], :owner => user) }

  context "with valid data but no link" do
    before do
      login_as(user)

      click_link("Palestras", match: :first)
      click_link "Adicionar palestra"

      fill_in "Título", :with => "A linguagem C"
      fill_in "Descrição", :with => "Indrodução à linguagem C"
      fill_in "Tags", :with => "C, programação"
      fill_in "Link do vídeo", :with => "http://www.youtube.com/invalid"
      check("Quero publicar")

      click_button "Adicionar palestra"
    end

    it "redirects to the talk page" do
      expect(current_path).to match(%r[/talks/\w+])
    end

    it "displays success message" do
      expect(page).to have_content("A palestra foi adicionada!")
    end
  end

  context "with invalid data" do
    before do
      login_as(user)

      click_link("Palestras", match: :first)
      click_link "Adicionar palestra"

      click_button "Adicionar palestra"
    end

    it "renders form page" do
      expect(current_path).to eql(talks_path)
    end

    it "displays error messages" do
      expect(page).to have_content("Verifique o formulário antes de continuar:")
    end
  end

  context "when the presentation are not found" do
    before do
      stub_request(:get, /slideshare.net/).
        with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(
          :status => 404,
          :body => '',
          :headers => {}
        )

      login_as(user)

      click_link("Palestras", match: :first)
      click_link "Adicionar palestra"

      fill_in "Link da palestra", :with => "http://www.slideshare.net/luizsanches/invalid"
      fill_in "Título", :with => "Compartilhe!"
    end

    it "displays error message" do
      expect(page).to have_content("Palestra não encontrada")
    end
  end

  context "with repeated talk" do
    before do
      login_as(user)

      click_link("Palestras", match: :first)
      click_link "Adicionar palestra"

      fill_in "Link da palestra", :with => "http://www.slideshare.net/luizsanches/compartilhe"
      fill_in "Descrição", :with => "Palestra duplicada"
      fill_in "Tags", :with => "duplicada"

      click_button "Adicionar palestra"
    end

    it "renders form page" do
      expect(current_path).to eql(talks_path)
    end

    it "displays error messages" do
      expect(page).to have_content("Link da palestra já está em uso")
    end
  end
end
