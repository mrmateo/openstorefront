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
package edu.usu.sdl.openstorefront.service.manager;

import edu.usu.sdl.openstorefront.exception.OpenStorefrontRuntimeException;
import edu.usu.sdl.openstorefront.service.ServiceProxy;
import edu.usu.sdl.openstorefront.service.io.ArticleImporter;
import edu.usu.sdl.openstorefront.service.io.AttributeImporter;
import edu.usu.sdl.openstorefront.service.io.ComponentImporter;
import edu.usu.sdl.openstorefront.service.io.HighlightImporter;
import edu.usu.sdl.openstorefront.service.io.LookupImporter;
import edu.usu.sdl.openstorefront.service.job.ErrorTicketCleanupJob;
import edu.usu.sdl.openstorefront.service.job.IntegrationJob;
import edu.usu.sdl.openstorefront.service.manager.model.JobModel;
import edu.usu.sdl.openstorefront.storage.model.ComponentIntegration;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.apache.commons.lang3.StringUtils;
import static org.quartz.CronScheduleBuilder.cronSchedule;
import org.quartz.JobBuilder;
import org.quartz.JobDataMap;
import org.quartz.JobDetail;
import org.quartz.JobKey;
import org.quartz.Scheduler;
import org.quartz.SchedulerException;
import static org.quartz.SimpleScheduleBuilder.simpleSchedule;
import org.quartz.Trigger;
import static org.quartz.TriggerBuilder.newTrigger;
import org.quartz.TriggerKey;
import org.quartz.impl.StdSchedulerFactory;
import org.quartz.impl.matchers.GroupMatcher;
import org.quartz.jobs.DirectoryScanJob;
import org.quartz.jobs.DirectoryScanListener;

/**
 * Handles Automation jobs
 *
 * @author dshurtleff
 */
public class JobManager
		implements Initializable
{

	private static final Logger log = Logger.getLogger(JobManager.class.getName());

	private static final String JOB_GROUP_SYSTEM = "SYSTEM";
	private static Scheduler scheduler;

	public static void init()
	{
		try {
			StdSchedulerFactory factory = new StdSchedulerFactory(FileSystemManager.getConfig("quartz.properties").getPath());
			scheduler = factory.getScheduler();
			initSystemJobs();
			scheduler.start();
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Failed to init quartz.", ex);
		}
	}

	private static void initSystemJobs() throws SchedulerException
	{
		log.log(Level.FINEST, "Setting up Import Jobs...");
		addImportJob(new LookupImporter(), FileSystemManager.IMPORT_LOOKUP_DIR);
		addImportJob(new AttributeImporter(), FileSystemManager.IMPORT_ATTRIBUTE_DIR);
		addImportJob(new ArticleImporter(), FileSystemManager.IMPORT_ARTICLE_DIR);
		addImportJob(new HighlightImporter(), FileSystemManager.IMPORT_HIGHLIGHT_DIR);
		addImportJob(new ComponentImporter(), FileSystemManager.IMPORT_COMPONENT_DIR);

		addCleanUpErrorsJob();
		addComponentIntegrationJobs();
	}

	private static void addComponentIntegrationJobs() throws SchedulerException
	{
		log.log(Level.INFO, "Adding Integration Jobs");

		ServiceProxy serviceProxy = new ServiceProxy();
		List<ComponentIntegration> integrations = serviceProxy.getComponentService().getComponentIntegrationModels(ComponentIntegration.ACTIVE_STATUS);
		for (ComponentIntegration integration : integrations) {
			addComponentIntegrationJob(integration);
		}
	}

	private static void addComponentIntegrationJob(ComponentIntegration componentIntegration) throws SchedulerException
	{
		ServiceProxy serviceProxy = new ServiceProxy();
		String jobName = "ComponentJob-" + componentIntegration.getComponentId();

		JobKey jobKey = JobKey.jobKey(jobName, JOB_GROUP_SYSTEM);
		if (scheduler.checkExists(jobKey)) {
			log.log(Level.WARNING, MessageFormat.format("Job already Exist: {0} check data", jobName));
		} else {
			JobDetail job = JobBuilder.newJob(IntegrationJob.class)
					.withIdentity("ComponentJob-" + componentIntegration.getComponentId(), JOB_GROUP_SYSTEM)
					.build();

			job.getJobDataMap().put(IntegrationJob.COMPONENT_ID, componentIntegration.getComponentId());
			String cron = componentIntegration.getRefreshRate();
			if (cron == null) {
				cron = serviceProxy.getSystemService().getGlobalIntegrationConfig().getJiraRefreshRate();
			}
			Trigger trigger = newTrigger()
					.withIdentity("ComponentTrigger-" + componentIntegration.getComponentId(), JOB_GROUP_SYSTEM)
					.startNow()
					.withSchedule(cronSchedule(cron))
					.build();

			scheduler.scheduleJob(job, trigger);
		}
	}

	/**
	 * Add or Update job
	 *
	 * @param componentIntegration
	 */
	public static void updateComponentIntegrationJob(ComponentIntegration componentIntegration)
	{
		try {
			removeComponentIntegrationJob(componentIntegration.getComponentId());
			addComponentIntegrationJob(componentIntegration);
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable update Job: " + componentIntegration.getComponentId(), ex);
		}
	}

	public static void removeComponentIntegrationJob(String componentId)
	{
		JobKey jobKey = JobKey.jobKey("ComponentJob-" + componentId, JOB_GROUP_SYSTEM);
		try {
			if (scheduler.checkExists(jobKey)) {
				scheduler.deleteJob(jobKey);
			}
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable remove Job.", ex);
		}
	}

	public static void runComponentIntegrationNow(String componentId, String integrationConfigId)
	{
		JobKey jobKey = JobKey.jobKey("ComponentJob-" + componentId, JOB_GROUP_SYSTEM);
		try {
			JobDataMap jobDataMap = new JobDataMap();
			jobDataMap.put(IntegrationJob.COMPONENT_ID, componentId);
			if (StringUtils.isNotBlank(integrationConfigId)) {
				jobDataMap.put(IntegrationJob.CONFIG_ID, integrationConfigId);
			}
			scheduler.triggerJob(jobKey, jobDataMap);
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable run Job.", ex);
		}
	}

	public static void unscheduleSystemJob(String triggerName)
	{
		try {
			TriggerKey triggerKey = TriggerKey.triggerKey(triggerName, JOB_GROUP_SYSTEM);
			if (scheduler.checkExists(triggerKey)) {
				scheduler.unscheduleJob(triggerKey);
			}
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable unschedule Job.", ex);
		}
	}

	private static void addCleanUpErrorsJob() throws SchedulerException
	{
		log.log(Level.INFO, "Adding Error Clean up Job");

		JobDetail job = JobBuilder.newJob(ErrorTicketCleanupJob.class)
				.withIdentity("CleanUpErrorsJob", JOB_GROUP_SYSTEM)
				.build();

		Trigger trigger = newTrigger()
				.withIdentity("CleanUpErrorsJobTrigger", JOB_GROUP_SYSTEM)
				.startNow()
				.withSchedule(simpleSchedule()
						.withIntervalInMinutes(5)
						.repeatForever())
				.build();

		scheduler.scheduleJob(job, trigger);
	}

	private static void addImportJob(DirectoryScanListener directoryScanListener, String dirToWatch) throws SchedulerException
	{
		String jobName = directoryScanListener.getClass().getName();
		log.log(Level.INFO, MessageFormat.format("Adding DIRWatch Job: {0}", directoryScanListener.getClass().getName()));

		JobDetail job = JobBuilder.newJob(DirectoryScanJob.class)
				.withIdentity(jobName, JOB_GROUP_SYSTEM)
				.build();

		FileSystemManager.getDir(dirToWatch);
		job.getJobDataMap().put(DirectoryScanJob.DIRECTORY_NAME, dirToWatch);
		job.getJobDataMap().put(DirectoryScanJob.DIRECTORY_SCAN_LISTENER_NAME, directoryScanListener.getClass().getName());
		scheduler.getContext().put(directoryScanListener.getClass().getName(), directoryScanListener);
		Trigger trigger = newTrigger()
				.withIdentity(jobName + "Trigger", JOB_GROUP_SYSTEM)
				.startNow()
				.withSchedule(simpleSchedule()
						.withIntervalInSeconds(30)
						.repeatForever())
				.build();

		scheduler.scheduleJob(job, trigger);
	}

	public static void pauseSystemJob(String jobName)
	{
		try {
			scheduler.pauseJob(JobKey.jobKey(jobName, JOB_GROUP_SYSTEM));
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable to pause job", "Make sure job exists", ex);
		}
	}

	public static void resumeSystemJob(String jobName)
	{
		try {
			scheduler.resumeJob(JobKey.jobKey(jobName, JOB_GROUP_SYSTEM));
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable to pause job", "Make sure job exists", ex);
		}
	}

	public static void pauseScheduler()
	{
		try {
			scheduler.standby();
			log.info("Job Manager in Standby");
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable to pause scheduler", ex);
		}
	}

	public static void resumeScheduler()
	{
		try {
			scheduler.start();
			log.info("Job Manager restarted");
		} catch (SchedulerException ex) {
			throw new OpenStorefrontRuntimeException("Unable to resume scheduler", ex);
		}
	}

	public static String status()
	{
		String status = "Running";
		try {
			if (scheduler.isInStandbyMode()) {
				status = "In Standby";
			}
		} catch (SchedulerException ex) {
			Logger.getLogger(JobManager.class.getName()).log(Level.SEVERE, null, ex);
		}
		return status;
	}

	public static List<JobModel> getAllJobs()
	{
		List<JobModel> jobs = new ArrayList<>();
		try {
			Set<JobKey> jobKeys = scheduler.getJobKeys(GroupMatcher.anyGroup());
			for (JobKey jobKey : jobKeys) {
				JobModel jobModel = new JobModel();

				JobDetail jobDetail = scheduler.getJobDetail(jobKey);
				jobModel.setJobName(jobKey.getName());
				jobModel.setGroupName(jobKey.getGroup());
				jobModel.setDescription(jobDetail.getDescription());
				jobModel.setConcurrentExectionDisallowed(jobDetail.isConcurrentExectionDisallowed());
				jobModel.setDurable(jobDetail.isDurable());
				jobModel.setPersistJobDataAfterExecution(jobDetail.isPersistJobDataAfterExecution());
				jobModel.setRequestsRecovery(jobDetail.requestsRecovery());
				StringBuilder dataMap = new StringBuilder();
				for (String dataKey : jobDetail.getJobDataMap().getKeys()) {
					dataMap.append(dataKey).append(" : ").append(jobDetail.getJobDataMap().get(dataKey)).append(" | ");
				}
				jobModel.setJobData(dataMap.toString());

				List<Trigger> triggers = (List<Trigger>) scheduler.getTriggersOfJob(jobKey);
				if (triggers.isEmpty() == false) {
					//just grab the first trigger as we should only have one
					Trigger trigger = triggers.get(0);
					jobModel.setPrimaryTrigger(trigger.getKey().getName() + " - " + trigger.getKey().getGroup());
					jobModel.setPerviousFiredTime(trigger.getPreviousFireTime());
					jobModel.setNextFiredTime(trigger.getNextFireTime());
					jobModel.setStatus(scheduler.getTriggerState(trigger.getKey()).toString());
				}
				jobs.add(jobModel);
			}
		} catch (SchedulerException ex) {
			Logger.getLogger(JobManager.class.getName()).log(Level.SEVERE, null, ex);
		}
		return jobs;
	}

	public static void cleanup()
	{
		if (scheduler != null) {
			try {
				scheduler.shutdown();
			} catch (SchedulerException ex) {
				throw new OpenStorefrontRuntimeException("Failed to init quartz.", ex);
			}
		}
	}

	@Override
	public void initialize()
	{
		JobManager.init();
	}

	@Override
	public void shutdown()
	{
		JobManager.cleanup();
	}

}
