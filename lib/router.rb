require 'byebug'

class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
    
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    (req.path =~ @pattern && req.request_method.downcase.to_sym == @http_method) ? true : false
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    regex = Regexp.new "#{self.pattern}"
    match_data = regex.match(req.path)
    
    route_params = {}
    match_data.names.each do |key|
      route_params[key] = match_data[key]
    end
    controller = self.controller_class.new(req, res, route_params)
    controller.invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
    
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    #self.add_route(pattern, controller_class, action_name)
    define_method "#{http_method}" do |pattern, controller_class, action_name|
        self.add_route(pattern, http_method, controller_class, action_name)
    end
    
  end

  # should return the route that matches this request
  def match(req)
    self.routes.each do |route|
      return route if route.matches?(req)
    end
    return nil
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    if self.match(req)
      self.match(req).run(req, res)
    else
      res.status = 404
      res.body = ["no matching routes"]
    end
    
  end
end
