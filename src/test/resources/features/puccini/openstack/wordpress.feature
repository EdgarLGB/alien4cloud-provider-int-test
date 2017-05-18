Feature: Deploy wordpress with puccini in openstack
  # Tested features with this scenario:
  #   - Deployment of wordpress
  Scenario: Wordpress
    Given I am authenticated with "ADMIN" role

    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "master"
    And I upload the git archive "tosca-normative-types"

    # Puccini
#    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-puccini-plugin"
    And I upload a plugin from "../alien4cloud-puccini-plugin"

    # Create orchestrator
    And I create an orchestrator named "Mount doom orchestrator" and plugin name "alien4cloud-plugin-puccini" and bean name "puccini-orchestrator"
    And I get configuration for orchestrator "Mount doom orchestrator"
    And I enable the orchestrator "Mount doom orchestrator"

    # Configure for openstack
    And I set the information KeystoneUrl, Tenant, User, Region, Password defined in the environment for the account Openstack for puccini orchestrator "Mount doom orchestrator"

    # Create openstack location
    And I create a location named "Openstack location" and infrastructure type "Openstack" to the orchestrator "Mount doom orchestrator"

    And I create a resource of type "org.alien4cloud.puccini.openstack.nodes.Compute" named "Ubuntu" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the property "image" to the environment variable "image_id" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the property "flavor" to the environment variable "flavor_id" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the property "key_pair_name" to the environment variable "key_pair_name" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the complex property "security_group_names" with an environment variable "security_group_names" which is a list for a resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the property "user" to "ubuntu" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Openstack location"
    And I upload an artifact whose path is defined in the environment variable "key_content_path" for the property "key_content" of the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Openstack location"

    And I create a resource of type "org.alien4cloud.puccini.openstack.nodes.ExternalNetwork" named "ExternalNetwork" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the property "network_name" to "net-pub" for the resource named "ExternalNetwork" related to the location "Mount doom orchestrator"/"Openstack location"

    And I create a resource of type "org.alien4cloud.puccini.openstack.nodes.Network" named "PrivateNetwork" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the property "network_name" to "puccini-network" for the resource named "PrivateNetwork" related to the location "Mount doom orchestrator"/"Openstack location"
    And I update the property "cidr" to "192.168.1.0/24" for the resource named "PrivateNetwork" related to the location "Mount doom orchestrator"/"Openstack location"


    # Upload archives for plugin
    And I checkout the git archive from url "https://github.com/alien4cloud/alien4cloud-extended-types.git" branch "master"
    And I upload the git archive "alien4cloud-extended-types/alien-base-types"
    And I upload the git archive "alien4cloud-extended-types/alien-extended-storage-types"
    And I checkout the git archive from url "https://github.com/alien4cloud/samples.git" branch "master"
    And I upload the git archive "samples/apache"
    And I upload the git archive "samples/mysql"
    And I upload the git archive "samples/php"
    And I upload the git archive "samples/wordpress"
    And I successfully upload the local archive "topologies/topology-wordpress-openstack.yaml"

    # Application
    And I create a new application with name "Wordpress-Openstack-Puccini" and description "Wordpress with Puccini" based on the template with name "wordpress-topology-openstack"

    And I Set a unique location policy to "Mount doom orchestrator"/"Openstack location" for all nodes

    # Configure the substituted node
    And I substitute on the current application the node "PrivateNetwork" with the location resource "Mount doom orchestrator"/"Openstack location"/"PrivateNetwork"
    And I substitute on the current application the node "ExternalNetwork" with the location resource "Mount doom orchestrator"/"Openstack location"/"ExternalNetwork"


    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes

    And The URL which is defined in attribute "wordpress_url" of the node "wordpress" should work