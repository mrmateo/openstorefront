/*
 * Copyright 2014 Space Dynamics Laboratory - Utah State University Research Foundation.
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
package edu.usu.sdl.openstorefront.web.test.system;

import edu.usu.sdl.openstorefront.core.entity.UserProfile;
import edu.usu.sdl.openstorefront.web.test.BaseTestCase;

/**
 *
 * @author dshurtleff
 */
public class EmailTest
		extends BaseTestCase
{

	@Override
	protected void runInternalTest()
	{
		results.append("Generating email...<br>");
		UserProfile userProfile = getTestUserProfile();
		service.getUserService().sendTestEmail(userProfile.getUsername(), null);
		results.append("Email sent<br>");
	}

	@Override
	public String getDescription()
	{
		return "Email Test";
	}
}
