Feature: Deploy wordpress with puccini
  # Tested features with this scenario:
  #   - Deployment of wordpress
  Scenario: Wordpress
    Given I am authenticated with "ADMIN" role

    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "master"
    And I upload the git archive "tosca-normative-types"

    # Puccini
#    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-puccini-plugin"
    And I upload a plugin from "../alien4cloud-puccini-plugin"

    # Orchestrator and location
    And I create an orchestrator named "Mount doom orchestrator" and plugin name "alien4cloud-plugin-puccini" and bean name "puccini-orchestrator"
    And I get configuration for orchestrator "Mount doom orchestrator"
    And I set the information AccessKeyId, AccessKeySecret, RegionID defined in the environment for the account AWS for puccini orchestrator "Mount doom orchestrator"
    And I enable the orchestrator "Mount doom orchestrator"
    And I create a location named "AWS location" and infrastructure type "AWS" to the orchestrator "Mount doom orchestrator"
    And I create a resource of type "org.alien4cloud.puccini.aws.nodes.Instance" named "Small" related to the location "Mount doom orchestrator"/"AWS location"
    And I update the property "image_id" to "ami-47a23a30" for the resource named "Small" related to the location "Mount doom orchestrator"/"AWS location"
    And I update the property "instance_type" to "t2.small" for the resource named "Small" related to the location "Mount doom orchestrator"/"AWS location"
    And I update the property "key_name" to "Guobao" for the resource named "Small" related to the location "Mount doom orchestrator"/"AWS location"
    And I update the property "security_groups" to a list "ssh_only" for the resource named "Small" related to the location "Mount doom orchestrator"/"AWS location"
    And I update the property "user" to "ubuntu" for the resource named "Small" related to the location "Mount doom orchestrator"/"AWS location"
    And I upload an artifact whose path is defined in the environment variable "key_content_path" for the property "key_content" of the resource named "Small" related to the location "Mount doom orchestrator"/"AWS location"
    And I create a resource of type "org.alien4cloud.puccini.aws.nodes.PublicNetwork" named "Internet" related to the location "Mount doom orchestrator"/"AWS location"

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
    And I Set a unique location policy to "Mount doom orchestrator"/"AWS location" for all nodes

    And I set the following inputs properties
      | os_distribution | ubuntu |

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    And The URL which is defined in attribute "wordpress_url" of the node "wordpress" should work