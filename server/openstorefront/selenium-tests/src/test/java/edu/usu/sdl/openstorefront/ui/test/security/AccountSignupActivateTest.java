/*
 * Copyright 2017 Space Dynamics Laboratory - Utah State University Research Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package edu.usu.sdl.openstorefront.ui.test.security;
import edu.usu.sdl.openstorefront.ui.test.BrowserTestBase;
import static java.lang.Thread.sleep;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.junit.BeforeClass;
import org.junit.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.ExpectedCondition;
import org.openqa.selenium.support.ui.WebDriverWait;

/**
 * Note on this test we don't want to login
 *
 * @author dshurtleff
 */
public class AccountSignupActivateTest
		extends BrowserTestBase
{
    private static final Logger LOG = Logger.getLogger(BrowserTestBase.class.getName());
    @BeforeClass
    public static void setupTest(){

    }
    
    /**
     *
     */
    public AccountSignupActivateTest(){
   
    }
    
    @Test
    // Delete if active
    public void deleteIfPresent(){
        
    }

    @Test
    public void signupForm(){
        LOG.log(Level.INFO,"********** Starting the signupForm in AccountSignupActivateTest ************");
        // Navigate to the registration page
        for (WebDriver driver : webDriverUtil.getDrivers()) { 
           driver.get(webDriverUtil.getPage("registration.jsp"));
            try {
                Thread.sleep(2000);
            } catch (InterruptedException ex) {
                Logger.getLogger(AccountSignupActivateTest.class.getName()).log(Level.SEVERE, null, ex);
            }
           // Fill out the form
           LOG.log(Level.INFO,"********** FILLING OUT SIGNUP FORM NOW ************");   
           driver.findElement(By.xpath("//input[@name='username']")).sendKeys("autotest1");
           driver.findElement(By.xpath("//input[@name='password']")).sendKeys("autoTest1!");
           driver.findElement(By.xpath("//input[@name='confirmPassword']")).sendKeys("autoTest1!");
           driver.findElement(By.xpath("//input[@name='firstName']")).sendKeys("auto");
           driver.findElement(By.xpath("//input[@name='lastName']")).sendKeys("Test1");
           driver.findElement(By.xpath("//input[@name='organization']")).sendKeys("Air Force");
           driver.findElement(By.xpath("//input[@name='email']")).sendKeys("blaine.esplin@sdl.usu.edu");
           driver.findElement(By.xpath("//input[@name='phone']")).sendKeys("435-555-5555");
           // SUBMIT the form
           driver.findElement(By.xpath("//span[@id='button-1026-btnInnerEl']")).click();
           try {
                Thread.sleep(7000);
            } catch (InterruptedException ex) {
                Logger.getLogger(AccountSignupActivateTest.class.getName()).log(Level.SEVERE, null, ex);
           
       }
    }
}
   
    @Test
    public void activateAccount(){
        // Navigate to Admin Tools -> Application Management -> User Tools to activate
        LOG.log(Level.INFO,"********** Starting activateAccount in AccountsSignupActivateTest ************");
        for (WebDriver driver : webDriverUtil.getDrivers()) { 
           driver.get(webDriverUtil.getPage("AdminTool.action?load=User-Management"));
             try {
                Thread.sleep(2000);
            } catch (InterruptedException ex) {
                Logger.getLogger(AccountSignupActivateTest.class.getName()).log(Level.SEVERE, null, ex);}
            // Now filter by Locked/Disabled and Pending and activate.
            driver.findElement(By.xpath("//div[@id='filterActiveStatus-trigger-picker']")).click();
            driver.findElement(By.xpath("//li[contains(.,'Locked/Disabled')]")).click();
            driver.findElement(By.xpath("//div[@id='filterApprovalStatus-trigger-picker']")).click();
            driver.findElement(By.xpath("//li[contains(.,'Pending')]")).click();
            // Select and click Approve
            driver.findElement(By.xpath("//div[contains(.,'autotest1')]"));
            try {
                Thread.sleep(3000);
            } catch (InterruptedException ex) {
                Logger.getLogger(AccountSignupActivateTest.class.getName()).log(Level.SEVERE, null, ex); }
            driver.findElement(By.xpath("//a[contains(.,'Approve')]")).click();
              try {
                Thread.sleep(11000);
            } catch (InterruptedException ex) {
                Logger.getLogger(AccountSignupActivateTest.class.getName()).log(Level.SEVERE, null, ex); }
        }
    }
    
}
