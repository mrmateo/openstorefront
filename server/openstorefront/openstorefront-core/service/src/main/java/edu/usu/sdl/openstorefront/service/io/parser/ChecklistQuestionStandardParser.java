/*
 * Copyright 2016 Space Dynamics Laboratory - Utah State University Research Foundation.
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
package edu.usu.sdl.openstorefront.service.io.parser;

import com.fasterxml.jackson.core.type.TypeReference;
import edu.usu.sdl.openstorefront.common.exception.OpenStorefrontRuntimeException;
import edu.usu.sdl.openstorefront.common.util.StringProcessor;
import edu.usu.sdl.openstorefront.core.entity.ChecklistQuestion;
import edu.usu.sdl.openstorefront.core.spi.parser.BaseChecklistQuestionParser;
import edu.usu.sdl.openstorefront.core.spi.parser.reader.GenericReader;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 *
 * @author dshurtleff
 */
public class ChecklistQuestionStandardParser
		extends BaseChecklistQuestionParser
{

	@Override
	public String checkFormat(String mimeType, InputStream input)
	{
		if (mimeType.contains("json")
				|| mimeType.contains("application/json")
				|| mimeType.contains("application/octet-stream")
				|| mimeType.contains("text")) {
			return "";
		} else {
			return "Invalid format. Please upload a json file.";
		}
	}

	@Override
	protected GenericReader getReader(InputStream in)
	{
		return new GenericReader<ChecklistQuestion>(in)
		{
			private List<ChecklistQuestion> questions = new ArrayList<>();

			@Override
			public void preProcess()
			{
				try (InputStream inTemp = in) {
					questions = StringProcessor.defaultObjectMapper().readValue(inTemp, new TypeReference<List<ChecklistQuestion>>()
					{
					});
				} catch (IOException ex) {
					throw new OpenStorefrontRuntimeException(ex);
				}
				totalRecords = questions.size();
			}

			@Override
			public ChecklistQuestion nextRecord()
			{
				if (questions.size() > 0) {
					currentRecordNumber++;
					return questions.remove(0);
				} else {
					return null;
				}
			}

		};
	}

	@Override
	protected <T> Object parseRecord(T record)
	{
		ChecklistQuestion checklistQuestion = (ChecklistQuestion) record;
		return checklistQuestion;
	}

}
