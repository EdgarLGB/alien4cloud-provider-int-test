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
    And I successfully upload the local archive "csars/artifact-test"
    And I successfully upload the local archive "topologies/artifact_test"

    And I create a new application with name "artifact-test-puccini" and description "Artifact test with Puccini" based on the template with name "artifact_test"
    And I Set a unique location policy to "Mount doom orchestrator"/"AWS location" for all nodes
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
