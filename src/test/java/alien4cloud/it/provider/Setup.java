package alien4cloud.it.provider;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

import org.junit.Assert;

import alien4cloud.git.RepositoryManager;
import alien4cloud.it.Context;
import alien4cloud.it.application.ApplicationStepDefinitions;
import alien4cloud.it.application.ApplicationsDeploymentStepDefinitions;
import alien4cloud.it.cloud.CloudDefinitionsSteps;
import alien4cloud.it.common.CommonStepDefinitions;
import alien4cloud.it.security.AuthenticationStepDefinitions;
import alien4cloud.rest.utils.RestClient;
import alien4cloud.utils.FileUtil;
import cucumber.api.java.After;
import cucumber.api.java.Before;
import cucumber.api.java.en.And;

public class Setup {

    private static final RepositoryManager REPOSITORY_MANAGER = new RepositoryManager();

    public static final String GIT_URL_SUFFIX = ".git";

    private static final Path GIT_ARTIFACT_TARGET_PATH = Paths.get("target/gits");

    private static final Path CSAR_TARGET_PATH = Paths.get("target/csars");

    private static final String FASTCONNECT_NEXUS = "http://fastconnect.org/maven/service/local/artifact/maven/redirect?";

    private static final CommonStepDefinitions COMMON_STEP_DEFINITIONS = new CommonStepDefinitions();

    public static final Path LOCAL_TEST_DATA_PATH = Paths.get("src/test/resources");

    public static final String SCP_USER = "root";

    public static final int SCP_PORT = 22;

    public static final String PEM_PATH = "src/test/resources/keys/alienjenkins.pem";

    public static final AuthenticationStepDefinitions AUTHENTICATION_STEP_DEFINITIONS = new AuthenticationStepDefinitions();

    private void cleanUp() throws Throwable {
        if (ApplicationStepDefinitions.CURRENT_APPLICATION != null) {
            new ApplicationsDeploymentStepDefinitions().I_undeploy_it();
            ApplicationStepDefinitions.CURRENT_APPLICATION = null;
        }
        new CloudDefinitionsSteps().I_disable_all_clouds();
    }

    @Before
    public void beforeScenario() throws Throwable {
        AUTHENTICATION_STEP_DEFINITIONS.I_am_authenticated_with_role("ADMIN");
    }

    @After
    public void afterScenario() throws Throwable {
        cleanUp();
        COMMON_STEP_DEFINITIONS.beforeScenario();
    }

    @And("^I checkout the git archive from url \"([^\"]*)\" branch \"([^\"]*)\"$")
    public void I_checkout_the_git_archive_from_url_branch(String gitURL, String branch) throws Throwable {
        String localDirectoryName = gitURL.substring(gitURL.lastIndexOf('/') + 1);
        if (localDirectoryName.endsWith(GIT_URL_SUFFIX)) {
            localDirectoryName = localDirectoryName.substring(0, localDirectoryName.length() - GIT_URL_SUFFIX.length());
        }
        REPOSITORY_MANAGER.cloneOrCheckout(GIT_ARTIFACT_TARGET_PATH, gitURL, branch, localDirectoryName);
    }

    private void uploadArchive(Path source) throws Throwable {
        Path csarTargetPath = CSAR_TARGET_PATH.resolve(source.getFileName() + ".csar");
        FileUtil.zip(source, csarTargetPath);
        Context.getInstance().registerRestResponse(Context.getRestClientInstance().postMultipart("/rest/csars", "file", Files.newInputStream(csarTargetPath)));
        COMMON_STEP_DEFINITIONS.I_should_receive_a_RestResponse_with_no_error();
    }

    @And("^I upload the git archive \"([^\"]*)\"$")
    public void I_upload_the_git_archive(String folderToUpload) throws Throwable {
        Path csarSourceFolder = GIT_ARTIFACT_TARGET_PATH.resolve(folderToUpload);
        uploadArchive(csarSourceFolder);
        COMMON_STEP_DEFINITIONS.I_should_receive_a_RestResponse_with_no_error();
    }

    @And("^I upload a plugin from maven artifact \"([^\"]*)\"$")
    public void I_upload_a_plugin_from_maven_artifact(String artifact) throws Throwable {
        String[] artifactTokens = artifact.split(":");
        Assert.assertTrue(artifactTokens.length == 2 || artifactTokens.length == 3);
        String version = Context.VERSION;
        if (artifactTokens.length == 3) {
            version = artifactTokens[2];
        }
        String repository;
        if (version.endsWith("SNAPSHOT")) {
            repository = "opensource-snapshot";
        } else {
            repository = "opensource";
        }
        String groupId = artifactTokens[0];
        String artifactId = artifactTokens[1];
        String artifactUrl = FASTCONNECT_NEXUS + "r=" + repository + "&g=" + groupId + "&a=" + artifactId + "&v=" + version + "&p=zip";
        Path tempFile = Files.createTempFile(null, null);
        Files.copy(new RestClient(artifactUrl).getAsStream(""), tempFile, StandardCopyOption.REPLACE_EXISTING);
        Context.getInstance().registerRestResponse(Context.getRestClientInstance().postMultipart("/rest/plugin", "file", Files.newInputStream(tempFile)));
        COMMON_STEP_DEFINITIONS.I_should_receive_a_RestResponse_with_no_error();
    }

    @And("^I upload the local archive \"([^\"]*)\"$")
    public void I_upload_the_local_archive(String archive) throws Throwable {
        Path archivePath = LOCAL_TEST_DATA_PATH.resolve(archive);
        uploadArchive(archivePath);
        COMMON_STEP_DEFINITIONS.I_should_receive_a_RestResponse_with_no_error();
    }
}
