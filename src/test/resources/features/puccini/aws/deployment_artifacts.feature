Feature: Usage of deployment artifacts with Puccini
  # Tested features with this scenario:
  #   - Deployment artifact as a file and directory for nodes and relationships
  #   - Override deployment artifact in Alien
  Scenario: Usage of deployment artifacts with Puccini
    Given I am authenticated with "ADMIN" role

    # Archives
    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "master"
    And I upload the git archive "tosca-normative-types"

    # Puccini
#    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-puccini-plugin"
    And I upload a plugin from "../alien4cloud-puccini-plugin"

    # Orchestrator and location
    And I create an orchestrator named "Mount doom orchestrator" and plugin name "alien4cloud-plugin-puccini" and bean name "puccini-orchestrator"
    And I get configuration for orchestrator "Mount doom orchestrator"
    And I enable the orchestrator "Mount doom orchestrator"

    # Create the resources
    And I create a location named "Local docker location" and infrastructure type "Docker" to the orchestrator "Mount doom orchestrator"
    And I create a resource of type "org.alien4cloud.puccini.docker.nodes.Container" named "Ubuntu" related to the location "Mount doom orchestrator"/"Local docker location"
    And I update the property "image_id" to "alien4cloud/puccini-ubuntu-trusty" for the resource named "Ubuntu" related to the location "Mount doom orchestrator"/"Local docker location"
    And I create a resource of type "org.alien4cloud.puccini.docker.nodes.Network" named "Internet" related to the location "Mount doom orchestrator"/"Local docker location"
    And I update the property "cidr" to "10.0.0.0/8" for the resource named "Internet" related to the location "Mount doom orchestrator"/"Local docker location"

    # Upload archives for plugin
    And I checkout the git archive from url "https://github.com/alien4cloud/alien4cloud-extended-types.git" branch "master"
    And I upload the git archive "alien4cloud-extended-types/alien-base-types"
    And I upload the git archive "alien4cloud-extended-types/alien-extended-storage-types"
    And I successfully upload the local archive "csars/artifact-test"
    And I successfully upload the local archive "topologies/artifact_test"

    And I create a new application with name "artifact-test-puccini" and description "Artifact test with Puccini installed in local docker" based on the template with name "artifact_test"
    And I Set a unique location policy to "Mount doom orchestrator"/"Local docker location" for all nodes
    And I upload a file located at "src/test/resources/data/toOverride.txt" to the archive path "toOverride.txt"
    And I execute the operation
      | type              | org.alien4cloud.tosca.editor.operations.nodetemplate.UpdateNodeDeploymentArtifactOperation |
      | nodeName          | Artifacts                                                                                  |
      | artifactName      | to_be_overridden                                                                           |
      | artifactReference | toOverride.txt                                                                             |
    And I save the topology
    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes

    # test preserved deployment artifats
    When I download the remote file "/home/ubuntu/Artifacts/toBePreserved.txt" from the node "Compute" with the keypair defined in environment variable "key_content_path" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "csars/artifact-test/toBePreserved.txt"
    When I download the remote file "/home/ubuntu/ArtifactsYamlOverride/toBePreserved.txt" from the node "Compute" with the keypair defined in environment variable "key_content_path" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "csars/artifact-test/toBePreserved.txt"

    # test overridding from Alien4cloud
    When I download the remote file "/home/ubuntu/Artifacts/toOverride.txt" from the node "Compute" with the keypair defined in environment variable "key_content_path" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "data/toOverride.txt"

    #test overridding from yaml topology csar
    When I download the remote file "/home/ubuntu/ArtifactsYamlOverride/toOverrideFromYaml.txt" from the node "Compute" with the keypair defined in environment variable "key_content_path" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "topologies/artifact_test/toOverrideFromYaml.txt"

    #test artifacts of the relationship
    When I download the remote file "/home/ubuntu/relationship/ArtifactsYamlOverride/settingsRel.properties" from the node "Compute" with the keypair defined in environment variable "key_content_path" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "csars/artifact-test/settingsRel.properties"
