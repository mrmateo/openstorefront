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
package edu.usu.sdl.openstorefront.service.io.archive.export;

import com.fasterxml.jackson.core.type.TypeReference;
import edu.usu.sdl.openstorefront.common.util.StringProcessor;
import edu.usu.sdl.openstorefront.core.entity.ComponentTypeTemplate;
import edu.usu.sdl.openstorefront.service.io.archive.BaseExporter;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import net.java.truevfs.access.TFile;
import net.java.truevfs.access.TFileInputStream;
import net.java.truevfs.access.TFileOutputStream;

/**
 *
 * @author dshurtleff
 */
public class EntryTemplateExporter
		extends BaseExporter
{

	private static final Logger LOG = Logger.getLogger(EntryTemplateExporter.class.getName());
	private static final String DATA_DIR = "/entrytemplate/";

	@Override
	public int getPriority()
	{
		return 3;
	}

	@Override
	public String getExporterSupportEntity()
	{
		return ComponentTypeTemplate.class.getSimpleName();
	}

	@Override
	public List<BaseExporter> getAllRequiredExports()
	{
		List<BaseExporter> exporters = new ArrayList<>();
		exporters.add(this);
		return exporters;
	}

	@Override
	public void exportRecords()
	{
		ComponentTypeTemplate componentTypeTemplate = new ComponentTypeTemplate();
		componentTypeTemplate.setActiveStatus(ComponentTypeTemplate.ACTIVE_STATUS);
		List<ComponentTypeTemplate> templates = componentTypeTemplate.findByExample();

		File dataFile = new TFile(archiveBasePath + DATA_DIR + "templates.json");

		try (OutputStream out = new TFileOutputStream(dataFile)) {
			StringProcessor.defaultObjectMapper().writeValue(out, templates);
		} catch (IOException ex) {
			LOG.log(Level.WARNING, MessageFormat.format("Unable to export templates.{0}", ex));
			addError("Unable to export templates");
		}

		archive.setRecordsProcessed(archive.getRecordsProcessed() + templates.size());
		archive.setStatusDetails("Exported " + templates.size() + " entry templates");
		archive.save();
	}

	@Override
	public void importRecords()
	{
		File dataDir = new TFile(archiveBasePath + DATA_DIR);
		File files[] = dataDir.listFiles();
		if (files != null) {
			for (File dataFile : files) {
				try (InputStream in = new TFileInputStream(dataFile)) {
					archive.setStatusDetails("Importing: " + dataFile.getName());
					archive.save();

					List<ComponentTypeTemplate> templates = StringProcessor.defaultObjectMapper().readValue(in, new TypeReference<List<ComponentTypeTemplate>>()
					{
					});
					for (ComponentTypeTemplate template : templates) {
						service.getComponentService().saveComponentTemplate(template);
					}

					archive.setRecordsProcessed(archive.getRecordsProcessed() + templates.size());
					archive.save();

				} catch (Exception ex) {
					LOG.log(Level.WARNING, "Failed to Load templates", ex);
					addError("Unable to load templates: " + dataFile.getName());
				}
			}
		} else {
			LOG.log(Level.FINE, "No templates to load.");
		}
	}

	@Override
	public long getTotalRecords()
	{
		ComponentTypeTemplate componentTypeTemplate = new ComponentTypeTemplate();
		componentTypeTemplate.setActiveStatus(ComponentTypeTemplate.ACTIVE_STATUS);
		return service.getPersistenceService().countByExample(componentTypeTemplate);
	}

}
