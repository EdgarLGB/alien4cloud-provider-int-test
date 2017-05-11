Feature: Lifecycle test


  Background:
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
    And I update the property "instance_type" to "t2.nano" for the resource named "Small" related to the location "Mount doom orchestrator"/"AWS location"
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
    And I upload the git archive "samples/php"
    And I upload the git archive "samples/demo-lifecycle"

  Scenario: Scaling default 1 then 2,1,3,1 for A and B

    Given I am authenticated with "ADMIN" role

    And I create a new application with name "test-lifecycle-1" and description "Test lifecycle with Puccini" based on the template with name "demo-lifecycle"
    And I Set a unique location policy to "Mount doom orchestrator"/"AWS location" for all nodes
    And I set the following inputs properties
      | os_arch | x86_64 |
      | os_type | linux  |

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    And The URL which is defined in attribute "url" of the node "Registry" should work
    And I store the attribute "url" of the node "Registry" as registered string "registry_url"

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostA&idx=0" and fetch the response and store it in the context as "GenericHostA_0_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostB&idx=0" and fetch the response and store it in the context as "GenericHostB_0_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=0" and fetch the response and store it in the context as "GenericB_0_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericHostB&idx=0" and fetch the response and store it in the context as "GenericHostB_0_logs"
    Then the registered string "GenericHostB_0_logs" lines should match the following regex sequence
      | #\d+ - create                                            |
      | #\d+ - pre_configure_target/GenericB/0/${GenericB_0_id}  |
      | #\d+ - configure                                         |
      | #\d+ - post_configure_target/GenericB/0/${GenericB_0_id} |
      | #\d+ - start                                             |
      | #\d+ - add_source/GenericB/0/${GenericB_0_id}            |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=0" and fetch the response and store it in the context as "GenericB_0_logs"
    Then the registered string "GenericB_0_logs" lines should match the following regex sequence
      | #\d+ - create                                            |
      | #\d+ - pre_configure_target/GenericA/0/${GenericA_0_id}  |
      | #\d+ - configure                                         |
      | #\d+ - post_configure_target/GenericA/0/${GenericA_0_id} |
      | #\d+ - start                                             |
      | #\d+ - add_source/GenericA/0/${GenericA_0_id}            |
    And the registered string "GenericB_0_logs" lines should match the following regex sequence
      | #\d+ - create                                                    |
      | #\d+ - pre_configure_source/GenericHostB/0/${GenericHostB_0_id}  |
      | #\d+ - configure                                                 |
      | #\d+ - post_configure_source/GenericHostB/0/${GenericHostB_0_id} |
      | #\d+ - start                                                     |
      | #\d+ - add_target/GenericHostB/0/${GenericHostB_0_id}            |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericHostA&idx=0" and fetch the response and store it in the context as "GenericHostA_0_logs"
    Then the registered string "GenericHostA_0_logs" lines should match the following regex sequence
      | #\d+ - create                                            |
      | #\d+ - pre_configure_target/GenericA/0/${GenericA_0_id}  |
      | #\d+ - configure                                         |
      | #\d+ - post_configure_target/GenericA/0/${GenericA_0_id} |
      | #\d+ - start                                             |
      | #\d+ - add_source/GenericA/0/${GenericA_0_id}            |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_logs"
    Then the registered string "GenericA_0_logs" lines should match the following regex sequence
      | #\d+ - create                                                    |
      | #\d+ - pre_configure_source/GenericHostA/0/${GenericHostA_0_id}  |
      | #\d+ - configure                                                 |
      | #\d+ - post_configure_source/GenericHostA/0/${GenericHostA_0_id} |
      | #\d+ - start                                                     |
      | #\d+ - add_target/GenericHostA/0/${GenericHostA_0_id}            |
    And the registered string "GenericA_0_logs" lines should match the following regex sequence
      | #\d+ - create                                            |
      | #\d+ - pre_configure_source/GenericB/0/${GenericB_0_id}  |
      | #\d+ - configure                                         |
      | #\d+ - post_configure_source/GenericB/0/${GenericB_0_id} |
      | #\d+ - start                                             |
      | #\d+ - add_target/GenericB/0/${GenericB_0_id}            |


         # ---------------------------------------------------------
         # Scale up 1 the ComputeB (target of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale up the node "ComputeB" by adding 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "GenericB" should contain 2 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostB&idx=1" and fetch the response and store it in the context as "GenericHostB_1_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=1" and fetch the response and store it in the context as "GenericB_1_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericHostB&idx=1" and fetch the response and store it in the context as "GenericHostB_1_logs"
    Then the registered string "GenericHostB_1_logs" lines should match the following regex sequence
      | #\d+ - create                                            |
      | #\d+ - pre_configure_target/GenericB/1/${GenericB_1_id}  |
      | #(\d+) - configure                                       |
      | #\d+ - post_configure_target/GenericB/1/${GenericB_1_id} |
      | #\d+ - start                                             |
      | #\d+ - add_source/GenericB/1/${GenericB_1_id}            |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=1" and fetch the response and store it in the context as "GenericB_1_logs"
    Then the registered string "GenericB_1_logs" lines should match the following regex sequence
      | #\d+ - create                                                    |
      | #\d+ - pre_configure_source/GenericHostB/1/${GenericHostB_1_id}  |
      | #\d+ - configure                                                 |
      | #\d+ - post_configure_source/GenericHostB/1/${GenericHostB_1_id} |
      | #\d+ - start                                                     |
      | #\d+ - add_target/GenericHostB/1/${GenericHostB_1_id}            |
    And the registered string "GenericB_1_logs" lines should match the following regex sequence
      | #\d+ - create                                            |
      | #\d+ - pre_configure_target/GenericA/0/${GenericA_0_id}  |
      | #\d+ - configure                                         |
      | #\d+ - post_configure_target/GenericA/0/${GenericA_0_id} |
      | #\d+ - start                                             |
      | #\d+ - add_source/GenericA/0/${GenericA_0_id}            |
    And I can catch the following groups in one line of the registered string "GenericHostB_1_logs" and store them as registered strings
      | #(\d+) - configure             |
      | GenericHostB_1_configure_opIdx |
    When I expand the string "${registry_url}/get_env_log.php?idx=${GenericHostB_1_configure_opIdx}" and store it as "GenericHostB_1_configure_env_url" in the context
    And I call the URL which is defined in registered string "GenericHostB_1_configure_env_url" with path "" and fetch the response and store it in the context as "GenericHostB_1_configure_env"
    Then the following expanded regex should be found in the registered string "GenericHostB_1_configure_env"
      | ^NODE=GenericHostB$                  |
      | ^INSTANCE=${GenericHostB_1_id}$      |
      | ^INSTANCES=.*${GenericHostB_1_id}.*$ |
      | ^INSTANCES=.*${GenericHostB_0_id}.*$ |
      | ^${GenericHostB_1_id}_IP_ADDR=.+$    |
      | ^${GenericHostB_0_id}_IP_ADDR=.+$    |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_logs"
    Then the registered string "GenericA_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/1/${GenericB_1_id} |


         # ---------------------------------------------------------
         # Scale up 1 the ComputeA (source of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale up the node "ComputeA" by adding 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "GenericA" should contain 2 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericA&idx=1" and fetch the response and store it in the context as "GenericA_1_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostA&idx=1" and fetch the response and store it in the context as "GenericHostA_1_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericHostA&idx=1" and fetch the response and store it in the context as "GenericHostA_1_logs"
    Then the registered string "GenericHostA_1_logs" lines should match the following regex sequence
      | #\d+ - create                                            |
      | #\d+ - pre_configure_target/GenericA/1/${GenericA_1_id}  |
      | #\d+ - configure                                         |
      | #\d+ - post_configure_target/GenericA/1/${GenericA_1_id} |
      | #\d+ - start                                             |
      | #\d+ - add_source/GenericA/1/${GenericA_1_id}            |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=1" and fetch the response and store it in the context as "GenericA_1_logs"
    Then the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - create                                                    |
      | #\d+ - pre_configure_source/GenericHostA/1/${GenericHostA_1_id}  |
      | #\d+ - configure                                                 |
      | #\d+ - post_configure_source/GenericHostA/1/${GenericHostA_1_id} |
      | #\d+ - start                                                     |
      | #\d+ - add_target/GenericHostA/1/${GenericHostA_1_id}            |
    And the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - create                                |
      | #\d+ - pre_configure_source/GenericB/\d+/.+  |
      | #\d+ - configure                             |
      | #\d+ - post_configure_source/GenericB/\d+/.+ |
      | #\d+ - start                                 |
    And the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/1/${GenericB_1_id} |
    And the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/0/${GenericB_0_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=0" and fetch the response and store it in the context as "GenericB_0_logs"
    Then the registered string "GenericB_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/1/${GenericA_1_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=1" and fetch the response and store it in the context as "GenericB_1_logs"
    Then the registered string "GenericB_1_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/1/${GenericA_1_id} |


         # ---------------------------------------------------------
         # Scale down the ComputeB (target of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale down the node "ComputeB" by removing 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "ComputeB" should contain 1 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericB&position=0" and fetch the response and store it in the context as "GenericB_stopped_0_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericB&idx=${GenericB_stopped_0_idx}" and store it as "GenericB_stopped_0_id_url" in the context
    And I call the URL which is defined in registered string "GenericB_stopped_0_id_url" with path "" and fetch the response and store it in the context as "GenericB_stopped_0_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericB&idx=${GenericB_stopped_0_idx}" and store it as "GenericB_stopped_0_log_url" in the context
    And I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericHostB&position=0" and fetch the response and store it in the context as "GenericHostB_stopped_0_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericHostB&idx=${GenericHostB_stopped_0_idx}" and store it as "GenericHostB_stopped_0_id_url" in the context
    And I call the URL which is defined in registered string "GenericHostB_stopped_0_id_url" with path "" and fetch the response and store it in the context as "GenericHostB_stopped_0_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericHostB&idx=${GenericHostB_stopped_0_idx}" and store it as "GenericHostB_stopped_0_log_url" in the context

    Given I call the URL which is defined in registered string "registry_url" with path "/get_remaining_idx.php?node=GenericB&position=0" and fetch the response and store it in the context as "GenericB_remaining_0_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericB&idx=${GenericB_remaining_0_idx}" and store it as "GenericB_remaining_0_id_url" in the context
    And I call the URL which is defined in registered string "GenericB_remaining_0_id_url" with path "" and fetch the response and store it in the context as "GenericB_remaining_0_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericB&idx=${GenericB_remaining_0_idx}" and store it as "GenericB_remaining_0_log_url" in the context

    When I call the URL which is defined in registered string "GenericB_stopped_0_log_url" with path "" and fetch the response and store it in the context as "GenericB_stopped_0_logs"
    Then the registered string "GenericB_stopped_0_logs" lines should match the following regex sequence
    #FIXME: different order for the workflow
#      | #\d+ - stop                                                                                  |
#      | #\d+ - remove_target/GenericHostB/${GenericHostB_stopped_0_idx}/${GenericHostB_stopped_0_id} |
#      | #\d+ - delete                                                                                |
      | #\d+ - remove_target/GenericHostB/${GenericHostB_stopped_0_idx}/${GenericHostB_stopped_0_id} |
      | #\d+ - stop                                                                                  |
      | #\d+ - delete                                                                                |
    And the registered string "GenericB_stopped_0_logs" lines should match the following regex sequence
    #FIXME: different order for the workflow
#      | #\d+ - stop                                      |
#      | #\d+ - remove_source/GenericA/1/${GenericA_1_id} |
#      | #\d+ - delete                                    |
      | #\d+ - remove_source/GenericA/1/${GenericA_1_id} |
      | #\d+ - stop                                      |
      | #\d+ - delete                                    |
    And the registered string "GenericB_stopped_0_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                      |
#      | #\d+ - remove_source/GenericA/0/${GenericA_0_id} |
#      | #\d+ - delete                                    |
      | #\d+ - remove_source/GenericA/0/${GenericA_0_id} |
      | #\d+ - stop                                      |
      | #\d+ - delete                                    |

    When I call the URL which is defined in registered string "GenericHostB_stopped_0_log_url" with path "" and fetch the response and store it in the context as "GenericHostB_stopped_0_logs"
    Then the registered string "GenericHostB_stopped_0_logs" lines should match the following regex sequence
      | #\d+ - remove_source/GenericB/${GenericB_stopped_0_idx}/${GenericB_stopped_0_id} |
      | #\d+ - stop                                                                      |
      | #\d+ - delete                                                                    |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_logs"
    Then the registered string "GenericA_0_logs" lines should match the following regex sequence
      | #\d+ - add_target/GenericB/${GenericB_stopped_0_idx}/${GenericB_stopped_0_id}    |
      | #\d+ - remove_target/GenericB/${GenericB_stopped_0_idx}/${GenericB_stopped_0_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=1" and fetch the response and store it in the context as "GenericA_1_logs"
    Then the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - add_target/GenericB/${GenericB_stopped_0_idx}/${GenericB_stopped_0_id}    |
      | #\d+ - remove_target/GenericB/${GenericB_stopped_0_idx}/${GenericB_stopped_0_id} |


         # ---------------------------------------------------------
         # Scale down the ComputeA (source of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale down the node "ComputeA" by removing 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "ComputeA" should contain 1 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericA&position=0" and fetch the response and store it in the context as "GenericA_stopped_0_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericA&idx=${GenericA_stopped_0_idx}" and store it as "GenericA_stopped_0_id_url" in the context
    And I call the URL which is defined in registered string "GenericA_stopped_0_id_url" with path "" and fetch the response and store it in the context as "GenericA_stopped_0_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericA&idx=${GenericA_stopped_0_idx}" and store it as "GenericA_stopped_0_log_url" in the context
    And I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericHostA&position=0" and fetch the response and store it in the context as "GenericHostA_stopped_0_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericHostA&idx=${GenericHostA_stopped_0_idx}" and store it as "GenericHostA_stopped_0_id_url" in the context
    And I call the URL which is defined in registered string "GenericHostA_stopped_0_id_url" with path "" and fetch the response and store it in the context as "GenericHostA_stopped_0_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericHostA&idx=${GenericHostA_stopped_0_idx}" and store it as "GenericHostA_stopped_0_log_url" in the context

    Given I call the URL which is defined in registered string "registry_url" with path "/get_remaining_idx.php?node=GenericA&position=0" and fetch the response and store it in the context as "GenericA_remaining_0_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericA&idx=${GenericA_remaining_0_idx}" and store it as "GenericA_remaining_0_id_url" in the context
    And I call the URL which is defined in registered string "GenericA_remaining_0_id_url" with path "" and fetch the response and store it in the context as "GenericA_remaining_0_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericA&idx=${GenericA_remaining_0_idx}" and store it as "GenericA_remaining_0_log_url" in the context

    When I call the URL which is defined in registered string "GenericA_stopped_0_log_url" with path "" and fetch the response and store it in the context as "GenericA_stopped_0_logs"
    Then the registered string "GenericA_stopped_0_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                                                                  |
#      | #\d+ - remove_target/GenericHostA/${GenericHostA_stopped_0_idx}/${GenericHostA_stopped_0_id} |
#      | #\d+ - delete                                                                                |
      | #\d+ - remove_target/GenericHostA/${GenericHostA_stopped_0_idx}/${GenericHostA_stopped_0_id} |
      | #\d+ - stop                                                                                  |
      | #\d+ - delete                                                                                |
    And the registered string "GenericA_stopped_0_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                          |
#      | #\d+ - remove_target/GenericB/\d+/.+ |
#      | #\d+ - delete                        |
      | #\d+ - remove_target/GenericB/\d+/.+ |
      | #\d+ - stop                          |
      | #\d+ - delete                        |
    When I call the URL which is defined in registered string "GenericHostA_stopped_0_log_url" with path "" and fetch the response and store it in the context as "GenericHostA_stopped_0_logs"
    Then the registered string "GenericHostA_stopped_0_logs" lines should match the following regex sequence
      | #\d+ - remove_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id} |
      | #\d+ - stop                                                                      |
      | #\d+ - delete                                                                    |
    When I call the URL which is defined in registered string "GenericB_remaining_0_log_url" with path "" and fetch the response and store it in the context as "GenericB_remaining_0_logs"
    Then the registered string "GenericB_remaining_0_logs" lines should match the following regex sequence
      | #\d+ - add_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id}    |
      | #\d+ - remove_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id} |


         # ---------------------------------------------------------
         # Scale up 2 the ComputeA (source of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale up the node "ComputeA" by adding 2 instance(s)
    Then I should receive a RestResponse with no error
    And The node "GenericA" should contain 3 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericA&idx=2" and fetch the response and store it in the context as "GenericA_2_id"
    # FIXME idx=3
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericA&idx=3" and fetch the response and store it in the context as "GenericA_3_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=2" and fetch the response and store it in the context as "GenericA_2_logs"
    Then the registered string "GenericA_2_logs" lines should match the following regex sequence
      | #\d+ - start                                                                      |
      | #\d+ - add_target/GenericB/${GenericB_remaining_0_idx}/${GenericB_remaining_0_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=3" and fetch the response and store it in the context as "GenericA_3_logs"
    Then the registered string "GenericA_3_logs" lines should match the following regex sequence
      | #\d+ - start                                                                      |
      | #\d+ - add_target/GenericB/${GenericB_remaining_0_idx}/${GenericB_remaining_0_id} |
    When I call the URL which is defined in registered string "GenericB_remaining_0_log_url" with path "" and fetch the response and store it in the context as "GenericB_remaining_0_logs"
    Then the registered string "GenericB_remaining_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/2/${GenericA_2_id} |
    And the registered string "GenericB_remaining_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/3/${GenericA_3_id} |


         # ---------------------------------------------------------
         # Scale up 2 the ComputeB (target of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale up the node "ComputeB" by adding 2 instance(s)
    Then I should receive a RestResponse with no error
    And The node "GenericB" should contain 3 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=2" and fetch the response and store it in the context as "GenericB_2_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=3" and fetch the response and store it in the context as "GenericB_3_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=2" and fetch the response and store it in the context as "GenericB_2_logs"
    Then the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - create                                                                     |
      | #\d+ - pre_configure_target/GenericA/\d+/.*                                       |
      | #\d+ - configure                                                                  |
      | #\d+ - start                                                                      |
      | #\d+ - add_source/GenericA/${GenericA_remaining_0_idx}/${GenericA_remaining_0_id} |
    And the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/2/${GenericA_2_id} |
    And the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/3/${GenericA_3_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=3" and fetch the response and store it in the context as "GenericB_3_logs"
    Then the registered string "GenericB_3_logs" lines should match the following regex sequence
      | #\d+ - create                                                                     |
      | #\d+ - pre_configure_target/GenericA/\d+/.*                                       |
      | #\d+ - configure                                                                  |
      | #\d+ - start                                                                      |
      | #\d+ - add_source/GenericA/${GenericA_remaining_0_idx}/${GenericA_remaining_0_id} |
    And the registered string "GenericB_3_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/2/${GenericA_2_id} |
    And the registered string "GenericB_3_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/3/${GenericA_3_id} |
    When I call the URL which is defined in registered string "GenericA_remaining_0_log_url" with path "" and fetch the response and store it in the context as "GenericA_remaining_0_logs"
    Then the registered string "GenericA_remaining_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/2/${GenericB_2_id} |
    And the registered string "GenericA_remaining_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/3/${GenericB_3_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=2" and fetch the response and store it in the context as "GenericA_2_logs"
    Then the registered string "GenericA_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/2/${GenericB_2_id} |
    And the registered string "GenericA_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/3/${GenericB_3_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=3" and fetch the response and store it in the context as "GenericA_3_logs"
    Then the registered string "GenericA_3_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/2/${GenericB_2_id} |
    And the registered string "GenericA_3_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/3/${GenericB_3_id} |


         # ---------------------------------------------------------
         # Scale down 2 the ComputeA (source of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale down the node "ComputeA" by removing 2 instance(s)
    Then I should receive a RestResponse with no error
    And The node "ComputeA" should contain 1 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericA&position=1" and fetch the response and store it in the context as "GenericA_stopped_1_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericA&idx=${GenericA_stopped_1_idx}" and store it as "GenericA_stopped_1_id_url" in the context
    And I call the URL which is defined in registered string "GenericA_stopped_1_id_url" with path "" and fetch the response and store it in the context as "GenericA_stopped_1_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericA&idx=${GenericA_stopped_1_idx}" and store it as "GenericA_stopped_1_log_url" in the context
    And I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericA&position=0" and fetch the response and store it in the context as "GenericA_stopped_0_idx"
    And I expand the string "${registry_url}/get_instance_id.php?node=GenericA&idx=${GenericA_stopped_0_idx}" and store it as "GenericA_stopped_0_id_url" in the context
    And I call the URL which is defined in registered string "GenericA_stopped_0_id_url" with path "" and fetch the response and store it in the context as "GenericA_stopped_0_id"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericA&idx=${GenericA_stopped_0_idx}" and store it as "GenericA_stopped_0_log_url" in the context

    When I call the URL which is defined in registered string "GenericA_stopped_1_log_url" with path "" and fetch the response and store it in the context as "GenericA_stopped_1_logs"
    Then the registered string "GenericA_stopped_1_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                                                          |
#      | #\d+ - remove_target/GenericB/${GenericB_remaining_0_idx}/${GenericB_remaining_0_id} |
#      | #\d+ - delete                                                                        |
      | #\d+ - remove_target/GenericB/${GenericB_remaining_0_idx}/${GenericB_remaining_0_id} |
      | #\d+ - stop                                                                          |
      | #\d+ - delete                                                                        |
    And the registered string "GenericA_stopped_1_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                      |
#      | #\d+ - remove_target/GenericB/2/${GenericB_2_id} |
#      | #\d+ - delete                                    |
      | #\d+ - remove_target/GenericB/2/${GenericB_2_id} |
      | #\d+ - stop                                      |
      | #\d+ - delete                                    |
    And the registered string "GenericA_stopped_1_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                      |
#      | #\d+ - remove_target/GenericB/3/${GenericB_3_id} |
#      | #\d+ - delete                                    |
      | #\d+ - remove_target/GenericB/3/${GenericB_3_id} |
      | #\d+ - stop                                      |
      | #\d+ - delete                                    |
    When I call the URL which is defined in registered string "GenericA_stopped_0_log_url" with path "" and fetch the response and store it in the context as "GenericA_stopped_0_logs"
    Then the registered string "GenericA_stopped_0_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                                                          |
#      | #\d+ - remove_target/GenericB/${GenericB_remaining_0_idx}/${GenericB_remaining_0_id} |
#      | #\d+ - delete                                                                        |
      | #\d+ - remove_target/GenericB/3/${GenericB_3_id} |
      | #\d+ - stop                                      |
      | #\d+ - delete                                    |
    And the registered string "GenericA_stopped_0_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                      |
#      | #\d+ - remove_target/GenericB/2/${GenericB_2_id} |
#      | #\d+ - delete                                    |
      | #\d+ - remove_target/GenericB/2/${GenericB_2_id} |
      | #\d+ - stop                                      |
      | #\d+ - delete                                    |
    And the registered string "GenericA_stopped_0_logs" lines should match the following regex sequence
        #FIXME: different order for the workflow
#      | #\d+ - stop                                      |
#      | #\d+ - remove_target/GenericB/3/${GenericB_3_id} |
#      | #\d+ - delete                                    |
      | #\d+ - remove_target/GenericB/3/${GenericB_3_id} |
      | #\d+ - stop                                      |
      | #\d+ - delete                                    |
    When I call the URL which is defined in registered string "GenericB_remaining_0_log_url" with path "" and fetch the response and store it in the context as "GenericB_remaining_0_logs"
    Then the registered string "GenericB_remaining_0_logs" lines should match the following regex sequence
      | #\d+ - add_source/GenericA/${GenericA_stopped_1_idx}/${GenericA_stopped_1_id}    |
      | #\d+ - remove_source/GenericA/${GenericA_stopped_1_idx}/${GenericA_stopped_1_id} |
    And the registered string "GenericB_remaining_0_logs" lines should match the following regex sequence
      | #\d+ - add_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id}    |
      | #\d+ - remove_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=2" and fetch the response and store it in the context as "GenericB_2_logs"
    Then the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - add_source/GenericA/${GenericA_stopped_1_idx}/${GenericA_stopped_1_id}    |
      | #\d+ - remove_source/GenericA/${GenericA_stopped_1_idx}/${GenericA_stopped_1_id} |
    And the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - add_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id}    |
      | #\d+ - remove_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id} |
    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=3" and fetch the response and store it in the context as "GenericB_3_logs"
    Then the registered string "GenericB_3_logs" lines should match the following regex sequence
      | #\d+ - add_source/GenericA/${GenericA_stopped_1_idx}/${GenericA_stopped_1_id}    |
      | #\d+ - remove_source/GenericA/${GenericA_stopped_1_idx}/${GenericA_stopped_1_id} |
    And the registered string "GenericB_3_logs" lines should match the following regex sequence
      | #\d+ - add_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id}    |
      | #\d+ - remove_source/GenericA/${GenericA_stopped_0_idx}/${GenericA_stopped_0_id} |


         # ---------------------------------------------------------
         # Scale down 2 the ComputeB (target of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale down the node "ComputeB" by removing 2 instance(s)
    Then I should receive a RestResponse with no error
    And The node "ComputeB" should contain 1 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericB&position=1" and fetch the response and store it in the context as "GenericB_stopped_1_idx"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericB&idx=${GenericB_stopped_1_idx}" and store it as "GenericB_stopped_1_log_url" in the context
    And I call the URL which is defined in registered string "registry_url" with path "/get_stopped_idx.php?node=GenericB&position=0" and fetch the response and store it in the context as "GenericB_stopped_0_idx"
    And I expand the string "${registry_url}/get_instance_log.php?node=GenericB&idx=${GenericB_stopped_0_idx}" and store it as "GenericB_stopped_0_log_url" in the context

    When I call the URL which is defined in registered string "GenericB_stopped_1_log_url" with path "" and fetch the response and store it in the context as "GenericB_2_logs"
    Then the registered string "GenericB_2_logs" lines should match the following regex sequence
      #FIXME: different order for the workflow
#      | #\d+ - stop                          |
#      | #\d+ - remove_source/GenericA/\d+/.+ |
#      | #\d+ - delete                        |
      | #\d+ - remove_source/GenericA/\d+/.+ |
      | #\d+ - stop                          |
      | #\d+ - delete                        |
    When I call the URL which is defined in registered string "GenericB_stopped_0_log_url" with path "" and fetch the response and store it in the context as "GenericB_3_logs"
    Then the registered string "GenericB_3_logs" lines should match the following regex sequence
    #FIXME: different order for the workflow
#      | #\d+ - stop                          |
#      | #\d+ - remove_source/GenericA/\d+/.+ |
#      | #\d+ - delete                        |
      | #\d+ - remove_source/GenericA/\d+/.+ |
      | #\d+ - stop                          |
      | #\d+ - delete                        |

  Scenario: Scaling default 2 then 3 for A and B
    Given I am authenticated with "ADMIN" role

    And I create a new application with name "test-lifecycle-2" and description "Test lifecycle with Puccini" based on the template with name "demo-lifecycle"
    And I execute the operation
      | type           | org.alien4cloud.tosca.editor.operations.nodetemplate.UpdateCapabilityPropertyValueOperation |
      | nodeName       | ComputeA                                                                                    |
      | capabilityName | scalable                                                                                    |
      | propertyName   | default_instances                                                                           |
      | propertyValue  | 2                                                                                           |
    And I execute the operation
      | type           | org.alien4cloud.tosca.editor.operations.nodetemplate.UpdateCapabilityPropertyValueOperation |
      | nodeName       | ComputeB                                                                                    |
      | capabilityName | scalable                                                                                    |
      | propertyName   | default_instances                                                                           |
      | propertyValue  | 2                                                                                           |
    And I save the topology
    And I Set a unique location policy to "Mount doom orchestrator"/"AWS location" for all nodes
    And I set the following inputs properties
      | os_arch | x86_64 |
      | os_type | linux  |

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    And The URL which is defined in attribute "url" of the node "Registry" should work
    And I store the attribute "url" of the node "Registry" as registered string "registry_url"

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostA&idx=0" and fetch the response and store it in the context as "GenericHostA_0_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostA&idx=1" and fetch the response and store it in the context as "GenericHostA_1_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostB&idx=0" and fetch the response and store it in the context as "GenericHostB_0_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericHostB&idx=1" and fetch the response and store it in the context as "GenericHostB_1_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericA&idx=1" and fetch the response and store it in the context as "GenericA_1_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=0" and fetch the response and store it in the context as "GenericB_0_id"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=1" and fetch the response and store it in the context as "GenericB_1_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_logs"
    Then the registered string "GenericA_0_logs" lines should match the following regex sequence
      | #\d+ - create                                 |
      | #\d+ - pre_configure_source/GenericB/\d+/.*   |
      | #\d+ - configure                              |
      | #\d+ - post_configure_source/GenericB/\d+/.*  |
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/0/${GenericB_0_id} |
    And the registered string "GenericA_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/1/${GenericB_1_id} |
    # FIXME pre_configure_source/GenericB/\d+/.* EXISTS 2 TIMES
    # It should be like this line in comment
#    And the registered string "GenericA_0_logs" lines should match the following regex only 1 time
    And the registered string "GenericA_0_logs" lines should match the following regex
      | #\d+ - create                                |
      | #\d+ - configure                             |
      | #\d+ - start                                 |
      | #\d+ - pre_configure_source/GenericB/\d+/.*  |
      | #\d+ - post_configure_source/GenericB/\d+/.* |


    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=1" and fetch the response and store it in the context as "GenericA_1_logs"
    Then the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - create                                 |
      | #\d+ - pre_configure_source/GenericB/\d+/.*   |
      | #\d+ - configure                              |
      | #\d+ - post_configure_source/GenericB/\d+/.*  |
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/0/${GenericB_0_id} |
    And the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/1/${GenericB_1_id} |


    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=0" and fetch the response and store it in the context as "GenericB_0_logs"
    Then the registered string "GenericB_0_logs" lines should match the following regex sequence
      | #\d+ - create                                 |
      | #\d+ - pre_configure_target/GenericA/\d+/.*   |
      | #\d+ - configure                              |
      | #\d+ - post_configure_target/GenericA/\d+/.*  |
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/0/${GenericA_0_id} |
    And the registered string "GenericB_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/1/${GenericA_1_id} |
    And the registered string "GenericB_0_logs" lines should match the following regex only 1 time
      | #\d+ - create                                |
      | #\d+ - configure                             |
      | #\d+ - start                                 |
      | #\d+ - pre_configure_target/GenericA/\d+/.*  |
      | #\d+ - post_configure_target/GenericA/\d+/.* |


    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=1" and fetch the response and store it in the context as "GenericB_1_logs"
    Then the registered string "GenericB_1_logs" lines should match the following regex sequence
      | #\d+ - create                                 |
      | #\d+ - pre_configure_target/GenericA/\d+/.*   |
      | #\d+ - configure                              |
      | #\d+ - post_configure_target/GenericA/\d+/.*  |
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/0/${GenericA_0_id} |
    And the registered string "GenericB_1_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/1/${GenericA_1_id} |


         # ---------------------------------------------------------
         # Let's test the inputs of the relation operations
         # ---------------------------------------------------------
    Given I can catch the following groups in one line of the registered string "GenericA_0_logs" and store them as registered strings
      | #(\d+) - add_target/GenericB/0/${GenericB_0_id} |
      | GenericA_0_add_target_GenericB_0_opIdx          |
    When I expand the string "${registry_url}/get_env_log.php?idx=${GenericA_0_add_target_GenericB_0_opIdx}" and store it as "GenericA_0_add_target_GenericB_0_env_url" in the context
    And I call the URL which is defined in registered string "GenericA_0_add_target_GenericB_0_env_url" with path "" and fetch the response and store it in the context as "GenericA_0_add_target_GenericB_0_env"
    Then the following expanded regex should be found in the registered string "GenericA_0_add_target_GenericB_0_env"
      | ^SOURCE_NODE=GenericA$                  |
      | ^SOURCE_INSTANCE=${GenericA_0_id}$      |
      | ^SOURCE_INSTANCES=.*${GenericA_0_id}.*$ |
      | ^SOURCE_INSTANCES=.*${GenericA_1_id}.*$ |
      | ^TARGET_NODE=GenericB$                  |
      | ^TARGET_INSTANCE=${GenericB_0_id}$      |
      | ^TARGET_INSTANCES=.*${GenericB_0_id}.*$ |
      | ^TARGET_INSTANCES=.*${GenericB_1_id}.*$ |
      | ^${GenericB_0_id}_TARGET_IP=.+$         |
      | ^${GenericB_1_id}_TARGET_IP=.+$         |

    Given I can catch the following groups in one line of the registered string "GenericB_0_logs" and store them as registered strings
      | #(\d+) - add_source/GenericA/0/${GenericA_0_id} |
      | GenericB_0_add_source_GenericA_0_opIdx          |
    When I expand the string "${registry_url}/get_env_log.php?idx=${GenericB_0_add_source_GenericA_0_opIdx}" and store it as "GenericB_0_add_source_GenericA_0_env_url" in the context
    And I call the URL which is defined in registered string "GenericB_0_add_source_GenericA_0_env_url" with path "" and fetch the response and store it in the context as "GenericB_0_add_source_GenericA_0_env"
    Then the following expanded regex should be found in the registered string "GenericB_0_add_source_GenericA_0_env"
      | ^SOURCE_NODE=GenericA$                  |
      | ^SOURCE_INSTANCE=${GenericA_0_id}$      |
      | ^SOURCE_INSTANCES=.*${GenericA_0_id}.*$ |
      | ^SOURCE_INSTANCES=.*${GenericA_1_id}.*$ |
      | ^TARGET_NODE=GenericB$                  |
      | ^TARGET_INSTANCE=${GenericB_0_id}$      |
      | ^TARGET_INSTANCES=.*${GenericB_0_id}.*$ |
      | ^TARGET_INSTANCES=.*${GenericB_1_id}.*$ |
      | ^${GenericA_0_id}_SOURCE_IP=.+$         |
      | ^${GenericA_1_id}_SOURCE_IP=.+$         |


         # ---------------------------------------------------------
         # Scale up 1 the ComputeA (source of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale up the node "ComputeA" by adding 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "GenericA" should contain 3 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericA&idx=2" and fetch the response and store it in the context as "GenericA_2_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=2" and fetch the response and store it in the context as "GenericA_2_logs"
    Then the registered string "GenericA_2_logs" lines should match the following regex sequence
      | #\d+ - create                                 |
      | #\d+ - pre_configure_source/GenericB/\d+/.*   |
      | #\d+ - configure                              |
      | #\d+ - post_configure_source/GenericB/\d+/.*  |
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/0/${GenericB_0_id} |
    And the registered string "GenericA_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/1/${GenericB_1_id} |
    And the registered string "GenericA_2_logs" lines should match the following regex only 1 time
      | #\d+ - create                                |
      | #\d+ - configure                             |
      | #\d+ - start                                 |
      | #\d+ - pre_configure_source/GenericB/\d+/.*  |
      | #\d+ - post_configure_source/GenericB/\d+/.* |

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=0" and fetch the response and store it in the context as "GenericB_0_logs"
    Then the registered string "GenericB_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/2/${GenericA_2_id} |

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=1" and fetch the response and store it in the context as "GenericB_1_logs"
    Then the registered string "GenericB_1_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/2/${GenericA_2_id} |


         # ---------------------------------------------------------
         # Scale up 1 the ComputeB (target of the relation A -> B)
         # ---------------------------------------------------------
    Given I wait for 30 seconds before continuing the test
    When I scale up the node "ComputeB" by adding 1 instance(s)
    Then I should receive a RestResponse with no error
    And The node "GenericB" should contain 3 instance(s) after at maximum 15 minutes
    And I wait for 10 seconds before continuing the test

    Given I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=2" and fetch the response and store it in the context as "GenericB_2_id"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericB&idx=2" and fetch the response and store it in the context as "GenericB_2_logs"
    Then the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - create                                 |
      | #\d+ - pre_configure_target/GenericA/\d+/.+   |
      | #\d+ - configure                              |
      | #\d+ - post_configure_target/GenericA/\d+/.+  |
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/0/${GenericA_0_id} |
    And the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/1/${GenericA_1_id} |
    And the registered string "GenericB_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_source/GenericA/2/${GenericA_2_id} |

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_logs"
    Then the registered string "GenericA_0_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/2/${GenericB_2_id} |

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=1" and fetch the response and store it in the context as "GenericA_1_logs"
    Then the registered string "GenericA_1_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/2/${GenericB_2_id} |

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=2" and fetch the response and store it in the context as "GenericA_2_logs"
    Then the registered string "GenericA_2_logs" lines should match the following regex sequence
      | #\d+ - start                                  |
      | #\d+ - add_target/GenericB/2/${GenericB_2_id} |


  Scenario: Should be able to read injected properties as input

    Given I am authenticated with "ADMIN" role

    And I create a new application with name "test-lifecycle-3" and description "Test lifecycle with Puccini" based on the template with name "demo-lifecycle"
    And I Set a unique location policy to "Mount doom orchestrator"/"AWS location" for all nodes
    And I set the following inputs properties
      | os_arch | x86_64 |
      | os_type | linux  |

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    And The URL which is defined in attribute "url" of the node "Registry" should work
    And I store the attribute "url" of the node "Registry" as registered string "registry_url"

    When I call the URL which is defined in registered string "registry_url" with path "/get_instance_log.php?node=GenericA&idx=0" and fetch the response and store it in the context as "GenericA_0_log"
    And I call the URL which is defined in registered string "registry_url" with path "/get_instance_id.php?node=GenericB&idx=0" and fetch the response and store it in the context as "GenericB_0_id"

    Given I can catch the following groups in one line of the registered string "GenericA_0_log" and store them as registered strings
      | #(\d+) - post_configure_source/GenericB/0/${GenericB_0_id} |
      | GenericA_0_post_configure_source_GenericB_0_opIdx          |
    When I expand the string "${registry_url}/get_env_log.php?idx=${GenericA_0_post_configure_source_GenericB_0_opIdx}" and store it as "GenericA_0_post_configure_source_GenericB_0_env_url" in the context
    And I call the URL which is defined in registered string "GenericA_0_post_configure_source_GenericB_0_env_url" with path "" and fetch the response and store it in the context as "GenericA_0_post_configure_source_GenericB_0_env"
    Then the following expanded regex should be found in the registered string "GenericA_0_post_configure_source_GenericB_0_env"
      | ^SOURCE_generic_property=default_value$ |
    Then the following expanded regex should be found in the registered string "GenericA_0_post_configure_source_GenericB_0_env"
      | ^TARGET_complex_prop=\\{$                     |
      | ^  "nested_map" : \\{$                        |
      | ^    "tutu" : "tata",$                        |
      | ^    "toctoc" : "tactac"$                     |
      | ^  \\},$                                      |
      | ^  "nested" : "node toto",$                   |
      | ^  "nested_array" : \\[ "titi", "tuctuc" \\]$ |
      | ^\\}$                                         |
