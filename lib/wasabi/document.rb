require 'wasabi/schema'
require 'wasabi/message'
require 'wasabi/port_type'
require 'wasabi/binding'
require 'wasabi/service'

class Wasabi
  class Document

    def initialize(document, wsdl)
      @document = document
      @wsdl = wsdl
    end

    def service_name
      @document.root['name']
    end

    def target_namespace
      @document.root['targetNamespace']
    end

    def namespaces
      @namespaces ||= collect_namespaces(@document, *schema_nodes)
    end

    def schemas
      @schemas ||= schema_nodes.map { |node| Schema.new(node, @wsdl) }
    end

    def imports
      imports = []

      @document.root.xpath('wsdl:import', 'wsdl' => Wasabi::WSDL).each do |node|
        location = node['location']
        imports << location if location
      end

      imports
    end

    # TODO: can we combine walking the root child nodes for each section?
    #       benchmark whether this would increase performance with economic.
    def messages
      @messages ||= begin
        nodes = @document.root.xpath('wsdl:message', 'wsdl' => Wasabi::WSDL)
        messages = nodes.map { |node| [node['name'], Message.new(node)] }
        Hash[messages]
      end
    end

    def port_types
      @port_types ||= begin
        nodes = @document.root.xpath('wsdl:portType', 'wsdl' => Wasabi::WSDL)
        port_types = nodes.map { |node| [node['name'], PortType.new(node)] }
        Hash[port_types]
      end
    end

    def bindings
      @bindings ||= begin
        nodes = @document.root.xpath('wsdl:binding', 'wsdl' => Wasabi::WSDL)
        bindings = nodes.map { |node| [node['name'], Binding.new(node)] }
        Hash[bindings]
      end
    end

    def services
      @services ||= begin
        nodes = @document.root.xpath('wsdl:service', 'wsdl' => Wasabi::WSDL)
        services = nodes.map { |node| [node['name'], Service.new(node)] }
        Hash[services]
      end
    end

    def service_node
      @document.root.at_xpath('wsdl:service', 'wsdl' => Wasabi::WSDL)
    end

    private

    def schema_nodes
      @schema_nodes ||= begin
        types = @document.root.at_xpath('wsdl:types', 'wsdl' => Wasabi::WSDL)
        types ? types.element_children : []
      end
    end

    def collect_namespaces(*nodes)
      namespaces = {}

      nodes.each do |node|
        node.namespaces.each do |k, v|
          key = k.sub(/^xmlns:/, '')
          namespaces[key] = v
        end
      end

      namespaces.delete('xmlns')
      namespaces
    end

  end
end
