require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @req = req
    @res = res
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    if @already_built_response
      raise "double render"
    else
      res.status = 302
      res['Location'] = url
      self.session.store_session(@res)
      @already_built_response = true
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    res['Content-Type'] = content_type
    
    if @already_built_response
      raise "double render"
    else
      res.body = [content]
      self.session.store_session(@res)
      @already_built_response = true
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.name.underscore
    path = File.dirname("views/#{controller_name}/#{template_name}.html.erb")
    template = File.join(path, "#{template_name}.html.erb")

    file = File.open(template, 'r')
    lines = file.read

    content = ERB.new("#{lines}").result(binding)

    self.render_content(content, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end

