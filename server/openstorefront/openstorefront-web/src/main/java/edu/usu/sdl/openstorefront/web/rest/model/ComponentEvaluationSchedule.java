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
package edu.usu.sdl.openstorefront.web.rest.model;

import java.util.Date;

/**
 *
 * @author dshurtleff
 */
public class ComponentEvaluationSchedule
{

	private String evaluationLevelCode;
	private Date completionDate;
	private String levelStatus;

	public ComponentEvaluationSchedule()
	{
	}

	public String getEvaluationLevelCode()
	{
		return evaluationLevelCode;
	}

	public void setEvaluationLevelCode(String evaluationLevelCode)
	{
		this.evaluationLevelCode = evaluationLevelCode;
	}

	public String getLevelStatus()
	{
		return levelStatus;
	}

	public void setLevelStatus(String levelStatus)
	{
		this.levelStatus = levelStatus;
	}

	public Date getCompletionDate()
	{
		return completionDate;
	}

	public void setCompletionDate(Date completionDate)
	{
		this.completionDate = completionDate;
	}

}
