require 'rspec'

class BasePage < SitePrism::Page
  include Capybara::DSL

  attr_reader :driver

  PRIMARY_NAV_ACTIONS = %i[register login logout]
  PRIMARY_NAV_TABS = %i[Solutions Products Downloads Resources Community Events Blogs]

  PRIMARY_NAV_ACTIONS.each do |action|
    element :"#{action}_link", ".#{action}"
  end

  PRIMARY_NAV_TABS.each do |tab|
    element :"primary_nav_#{tab.downcase}_link", :xpath, "//nav[@class='primary-nav']//ul/li/*[contains(text(),'#{tab}')]"
  end

  element :logged_in?, '.logged-in'
  element :logged_in_name_link, '.logged-in-name'
  element :p_title, '.blowout'
  element :loading_spinner, '.results loading'
  element :verification_message, '#kc-feedback-wrapper'
  element :logged_in_state, '.login'
  element :login_divider, '.login-divider'

  def initialize(driver)
    @driver = driver
  end

  def loaded?(title)
    if Capybara.current_driver == 'poltergeist'.to_sym
      raise("There was a problem loading the page, expected status code to be 200, but was #{page.status_code}") unless page.status_code.eql?(200)
    end
    raise("Expected page title to be #{title}, but was #{page.title}") unless page.has_title?(title).eql?(true)
    wait_for_ajax
  end

  def title
    p_title.text
  end

  def logged_in?
    visible?(true, '.logged-in') && visible?(true, '.logout') && visible?(false, '.register') && visible?(false, '.login')
  end

  def logged_out?
    visible?(false, '.logged-in') && visible?(false, '.logout') && visible?(true, '.login') && visible?(true, '.register')
  end

  def physical_logout
    try(3) {
      if logged_in?.eql?(true)
        logout_link.click
        wait_for_ajax
      end
      logged_out?
    }
  end

  def wait_for_ajax
    Timeout.timeout(30) do
      loop until finished_all_ajax_requests?
    end
  end

  def visible?(negate, css_selector)
    page.has_css?(css_selector, :visible => negate)
  end

  private

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active') == 0
  end

  def try(i)
    count = 0; logged_out = false
    until logged_out == true || count == i
      p ' . . . User is not logged out, retrying . . .'
      logged_out = yield
      sleep(3)
      count += 1
    end
    if logged_out.eql?(false)
      raise("User was not logged out after #{count} attempts")
    end
  end

end
