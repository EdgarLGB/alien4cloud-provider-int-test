package alien4cloud.it;

import cucumber.api.CucumberOptions;
import cucumber.api.junit.Cucumber;
import org.junit.runner.RunWith;

/**
 * 
 */
@RunWith(Cucumber.class)
@CucumberOptions(features = { "classpath:features/puccini/aws" }, format = { "pretty", "html:target/cucumber/puccini/aws",
        "json:target/cucumber/puccini/cucumber-aws.json" })
public class RunPucciniAWSIT {
}
