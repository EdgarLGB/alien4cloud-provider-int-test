Feature: Apache load balancer + tomcat
  # Tested features with this scenario:
  #   - Floating IP
  #   - Topology's output
  #   - concat function
  #   - get_operation_output function
  #   - Scale up/down
  #   - Custom command
  #   - Deployment of tomcat and apache load balancer
  Scenario: Apache load balancer + tomcat
    Given I am authenticated with "ADMIN" role

    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "master"
    And I upload the git archive "tosca-normative-types"

    # Puccini
#    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-puccini-plugin"
    And I upload a plugin from "../alien4cloud-puccini-plugin"

    # Orchestrator and location
    And I create an orchestrator named "Mount doom orchestrator" and plugin name "alien4cloud-plugin-puccini" and bean name "puccini-orchestrator"
    And I get configuration for orchestrator "Mount doom orchestrator"
    And I enable the orchestrator "Mount doom orchestrator"
    And I create a location named "Local docker location" and infrastructure type "Docker" to the orchestrator "Mount doom orchestrator"
    And I create a resource of type "org.alien4cloud.puccini.docker.nodes.Container" named "Ubuntu" related to the location "Mount doom orchestrator"/"Local docker location"
    And I update the property "image_id" to "alien4cloud/puccini-ubuntu-trusty" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Local docker location"
    And I create a resource of type "org.alien4cloud.puccini.docker.nodes.Network" named "Internet_Wordpress" related to the location "Mount doom orchestrator"/"Local docker location"
    And I update the property "cidr" to "10.0.0.0/8" for the resource named "Internet_Wordpress" related to the location "Mount doom orchestrator"/"Local docker location"
    And I update the property "network_name" to "network_wordpress" for the resource named "Internet_Wordpress" related to the location "Mount doom orchestrator"/"Local docker location"

    # Upload archives for plugin
    And I checkout the git archive from url "https://github.com/alien4cloud/alien4cloud-extended-types.git" branch "master"
    And I upload the git archive "alien4cloud-extended-types/alien-base-types"
    And I upload the git archive "alien4cloud-extended-types/alien-extended-storage-types"
    And I checkout the git archive from url "https://github.com/alien4cloud/samples.git" branch "master"
    And I upload the git archive "samples/jdk"
    And I upload the git archive "samples/apache-load-balancer"
    And I upload the git archive "samples/tomcat-war"
    And I upload the git archive "samples/topology-load-balancer-tomcat"

    And I create a new application with name "load-balancer" and description "Apache load balancer with Puccini installed in local docker" based on the template with name "war-apache-load-balanced-topology"

    # Modify the port of ApacheLoadBalancer to 8888
    And I execute the operation
      | type           | org.alien4cloud.tosca.editor.operations.nodetemplate.UpdateCapabilityPropertyValueOperation |
      | nodeName       | ApacheLoadBalancer                                                                          |
      | capabilityName | client                                                                                      |
      | propertyName   | port                                                                                        |
      | propertyValue  | 8888                                                                                        |
    And I successfully save the topology


    And I Set a unique location policy to "Mount doom orchestrator"/"Local docker location" for all nodes
    And I set the following inputs properties
      | os_arch | x86_64 |
      | os_type | linux  |

    # Set the exposed ports and port mappings
    And I update the complex property "exposed_ports" to """[{"protocol": "tcp", "port": "8888"}]""" for the substituted node "LoadBalancerServer"
    And I update the complex property "port_mappings" to """[{"from": "8888", "to": "8888"}]""" for the substituted node "LoadBalancerServer"

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    And The URL which is defined in attribute "load_balancer_url" of the node "ApacheLoadBalancer" should work and the html should contain "Welcome to Fastconnect !"
    And I should wait for 30 seconds before continuing the test

    When I trigger on the node template "War" the custom command "update_war_file" of the interface "custom" for application "load-balancer" with parameters:
      | WAR_URL | https://github.com/alien4cloud/alien4cloud-provider-int-test/raw/develop/src/test/resources/data/helloWorld.war |
    And I should wait for 30 seconds before continuing the test
    And The URL which is defined in attribute "load_balancer_url" of the node "ApacheLoadBalancer" should work and the html should contain "Welcome to testDeployArtifactOverriddenTest !"

    # Scale up/down part
    When I scale up the node "WebServer" by adding 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "War" should contain 2 instance(s) after at maximum 15 minutes
    And I should wait for 30 seconds before continuing the test
    And The URL which is defined in attribute "load_balancer_url" of the node "ApacheLoadBalancer" should work and the html should contain "Welcome to Fastconnect !" and "Welcome to testDeployArtifactOverriddenTest !"
    When I scale down the node "WebServer" by removing 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "War" should contain 1 instance(s) after at maximum 15 minutes
