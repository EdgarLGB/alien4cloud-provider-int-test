package alien4cloud.it;

import cucumber.api.CucumberOptions;
import cucumber.api.junit.Cucumber;
import org.junit.runner.RunWith;

/**
 *
 */
@RunWith(Cucumber.class)
@CucumberOptions(features = { "classpath:features/puccini/byon" }, format = { "pretty", "html:target/cucumber/puccini/byon",
        "json:target/cucumber/puccini/cucumber-byon.json" })
public class RunPucciniByonIT {
}
