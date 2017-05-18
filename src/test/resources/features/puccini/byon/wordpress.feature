Feature: Deploy wordpress with puccini using byon
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
    And I create a location named "Byon location" and infrastructure type "Byon" to the orchestrator "Mount doom orchestrator"

    # Create the compute nodes for computeDb and computeWww with ip, user, private_key
    And I create a resource of type "org.alien4cloud.puccini.byon.nodes.Compute" named "UbuntuDb" related to the location "Mount doom orchestrator"/"Byon location"
    And I update the property "ip_address" to the environment variable "ip_UbuntuDb" for the resource named "UbuntuDb" related to the location "Mount doom orchestrator"/"Byon location"
    And I update the property "user" to "vagrant" for the resource named "UbuntuDb" related to the location "Mount doom orchestrator"/"Byon location"
    And I upload an artifact whose path is defined in the environment variable "key_content_path_UbuntuDb" for the property "key_content" of the resource named "UbuntuDb" related to the location "Mount doom orchestrator"/"Byon location"

    And I create a resource of type "org.alien4cloud.puccini.byon.nodes.Compute" named "UbuntuWww" related to the location "Mount doom orchestrator"/"Byon location"
    And I update the property "ip_address" to the environment variable "ip_UbuntuWww" for the resource named "UbuntuWww" related to the location "Mount doom orchestrator"/"Byon location"
    And I update the property "user" to "vagrant" for the resource named "UbuntuWww" related to the location "Mount doom orchestrator"/"Byon location"
    And I upload an artifact whose path is defined in the environment variable "key_content_path_UbuntuWww" for the property "key_content" of the resource named "UbuntuWww" related to the location "Mount doom orchestrator"/"Byon location"

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

    And I Set a unique location policy to "Mount doom orchestrator"/"Byon location" for all nodes

    # Configure the substituted compute node
    And I substitute on the current application the node "computeDb" with the location resource "Mount doom orchestrator"/"Byon location"/"UbuntuDb"
    And I substitute on the current application the node "computeWww" with the location resource "Mount doom orchestrator"/"Byon location"/"UbuntuWww"

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes

    And The URL which is defined in attribute "wordpress_url" of the node "wordpress" should work