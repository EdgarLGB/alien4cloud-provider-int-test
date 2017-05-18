Feature: Deploy wordpress with puccini in local docker
  # Tested features with this scenario:
  #   - Deployment of wordpress
  Scenario: Wordpress
    Given I am authenticated with "ADMIN" role

    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "master"
    And I upload the git archive "tosca-normative-types"

    # Puccini
#    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-puccini-plugin"
    And I upload a plugin from "../alien4cloud-puccini-plugin"

    # Create orchestrator and location
    And I create an orchestrator named "Mount doom orchestrator" and plugin name "alien4cloud-plugin-puccini" and bean name "puccini-orchestrator"
    And I get configuration for orchestrator "Mount doom orchestrator"
    And I enable the orchestrator "Mount doom orchestrator"
    And I create a location named "Local docker location" and infrastructure type "Docker" to the orchestrator "Mount doom orchestrator"
    And I create a resource of type "org.alien4cloud.puccini.docker.nodes.Container" named "Ubuntu" related to the location "Mount doom orchestrator"/"Local docker location"
    And I update the property "image_id" to "alien4cloud/puccini-ubuntu-trusty" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Local docker location"


    # Upload archives for plugin
    And I checkout the git archive from url "https://github.com/alien4cloud/alien4cloud-extended-types.git" branch "master"
    And I upload the git archive "alien4cloud-extended-types/alien-base-types"
    And I upload the git archive "alien4cloud-extended-types/alien-extended-storage-types"
    And I checkout the git archive from url "https://github.com/alien4cloud/samples.git" branch "master"
    And I upload the git archive "samples/apache"
    And I upload the git archive "samples/mysql"
    And I upload the git archive "samples/php"
    And I upload the git archive "samples/wordpress"
    And I upload the git archive "samples/topology-wordpress"

    # Application
    And I create a new application with name "wordpress-puccini" and description "Wordpress with Puccini" based on the template with name "wordpress-topology"

    # Modify the port of apache to 8888
    And I execute the operation
      | type          | org.alien4cloud.tosca.editor.operations.nodetemplate.UpdateNodePropertyValueOperation |
      | nodeName      | apache                                                                                |
      | propertyName  | port                                                                                  |
      | propertyValue | 8888                                                                                  |
    And I successfully save the topology

    And I Set a unique location policy to "Mount doom orchestrator"/"Local docker location" for all nodes

    # Set the exposed ports and port mappings for the node computeWww
    And I update the complex property "exposed_ports" to """[{"protocol": "tcp", "port": "8888"}]""" for the substituted node "computeWww"
    And I update the complex property "port_mappings" to """[{"from": "8888", "to": "8888"}]""" for the substituted node "computeWww"

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes

    And The URL which is defined in attribute "wordpress_url" of the node "wordpress" should work