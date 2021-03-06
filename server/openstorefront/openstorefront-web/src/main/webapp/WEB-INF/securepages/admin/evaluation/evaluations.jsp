<%-- 
    Document   : evaluations
    Created on : Oct 11, 2016, 2:28:31 PM
    Author     : dshurtleff
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ taglib prefix="stripes" uri="http://stripes.sourceforge.net/stripes.tld" %>
<stripes:layout-render name="../../../../layout/toplevelLayout.jsp">
    <stripes:layout-component name="contents">
	
	<stripes:layout-render name="../../../../layout/adminheader.jsp">		
	</stripes:layout-render>		
		
	<script src="scripts/component/evaluationForm.js?v=${appVersion}" type="text/javascript"></script>	
		
	<script type="text/javascript">
		/* global Ext, CoreUtil */
		Ext.onReady(function(){	
			
		
			var createEvaluationWin = Ext.create('Ext.window.Window', {
				title: 'Create Evaluation',
				iconCls: 'fa fa-lg fa-plus icon-small-vertical-correction',
				modal: true,
				width: 550,
				maxHeight: '80%',
				layout: 'fit',
				items: [
					{
						xtype: 'form',
						itemId: 'form',
						bodyStyle: 'padding: 10px;',
						scrollable: true,
						dockedItems: [
							{
								xtype: 'toolbar',
								dock: 'bottom',
								items: [
									{
										text: 'Save',
										iconCls: 'fa fa-lg fa-save icon-button-color-save',
										handler: function(){
											var form = this.up('form');
											var data = form.getValues();
											
											CoreUtil.submitForm({
												url: 'api/v1/resource/evaluations',
												method: 'POST',
												data: data,
												form: form,
												success: function(){
													actionRefresh();
													form.reset();
													createEvaluationWin.close();
												}
											});
											
										}
									},
									{
										xtype: 'tbfill'
									},
									{
										text: 'Cancel',
										iconCls: 'fa fa-lg fa-close icon-button-color-warning',
										handler: function(){
											createEvaluationWin.close();
										}										
									}
								]
							}
						],
						layout: 'anchor',
						defaults: {
							labelAlign: 'top',
							labelSeparator: '',							
							width: '100%'
						},
						items: [							
							{
								xtype: 'combobox',
								fieldLabel: 'Entry <span class="field-required" />',
								name: 'componentId',
								displayField: 'description',
								valueField: 'code',								
								emptyText: 'Select an entry',
								allowBlank: false,
								forceSelection: true,
								store: {									
									autoLoad: true,
									proxy: {
										type: 'ajax',
										url: 'api/v1/resource/components/lookup?approvalState=ALL'
									}
								}						
							},
							{
								xtype: 'combobox',
								fieldLabel: 'Evaluation Template <span class="field-required" />',
								name: 'templateId',
								displayField: 'description',
								valueField: 'templateId',								
								emptyText: 'Select a Template',								
								allowBlank: false,
								typeAhead: false,
								editable: false,
								store: {									
									autoLoad: true,
									proxy: {
										type: 'ajax',
										url: 'api/v1/resource/evaluationtemplates'
									}
								}						
							},							
							{
								xtype: 'textfield',
								fieldLabel: 'Version <span class="field-required" />',
								name: 'version',								
								allowBlank: false,
								maxLength: 255
							},
							{
								xtype: 'combo',
								itemId: 'workflowStatus',
								name: 'workflowStatus',
								allowBlank: false,															
								editable: false,
								typeAhead: false,	
								valueField: 'code',
								displayField: 'description',
								fieldLabel: 'Status <span class="field-required" />',
								listConfig: {
									minWidth: '100px'
								},
								store: {
									proxy: {
										type: 'ajax',
										url: 'api/v1/resource/lookuptypes/WorkflowStatus'
									},
									listeners: {
										load: function(store, records) {											
											if (records && records.length > 0) {												
												var field = createEvaluationWin.getComponent('form').getComponent('workflowStatus');
												field.setValue(records[0].get('code'));
											}
										}										
									}
								}
							},							
							{
								xtype: 'combobox',
								name: 'assignedGroup',
								fieldLabel: 'Assign to Group',
								displayField: 'description',
								valueField: 'code',								
								emptyText: 'Unassigned',
								forceSelection: true,
								editable: false,
								store: {									
									autoLoad: true,
									proxy: {
										type: 'ajax',
										url: 'api/v1/resource/securityroles/lookup'
									},
									listeners: {
										load: function(store, records, opts) {
											store.add({
												code: null,
												description: 'Unassigned'
											});
										}
									}
								}									
							},
							{
								xtype: 'combobox',
								name: 'assignedUser',
								fieldLabel: 'Assign to User',
								displayField: 'description',
								valueField: 'code',								
								emptyText: 'Unassigned',
								forceSelection: true,
								editable: false,
								store: {									
									autoLoad: true,
									proxy: {
										type: 'ajax',
										url: 'api/v1/resource/userprofiles/lookup'
									},
									listeners: {
										load: function(store, records, opts) {
											store.add({
												code: null,
												description: 'Unassigned'
											});
										}
									}									
								}								
							},
							{
								xtype: 'checkbox',
								name: 'allowNewSections',
								boxLabel: 'Allow Adding Sections'
							}
/*							
							{
								xtype: 'checkbox',
								name: 'allowNewSubSections',
								boxLabel: 'Allow Adding Sub-Sections'
							}
*/							
						]
					}
				]
			});			
			
			var evaluationGrid = Ext.create('Ext.grid.Panel', {
				id: 'evaluationGrid',
				title: 'Manage Evaluation <i class="fa fa-question-circle"  data-qtip="Evaluations allow for creating detailed consumer report for an entry."></i>',
				columnLines: true,
				store: {
					id: 'evaluationGridStore',
					autoLoad: true,
					pageSize: 250,
					remoteSort: true,
					sorters: [
						new Ext.util.Sorter({
							property: 'componentName',
							direction: 'ASC'
						})
					],						
					fields: [
						{ 
							name: 'createDts', 
							type: 'date',
							dateFormat: 'c'							
						},
						{ 
							name: 'updateDts',
							type: 'date',
							dateFormat: 'c'				
						}							
					],
					proxy: CoreUtil.pagingProxy({
						type: 'ajax',
						url: 'api/v1/resource/evaluations',
						reader: {
							type: 'json',
							rootProperty: 'data',
							totalProperty: 'totalNumber'
						}
					}),										
					listeners: {
						beforeLoad: function(store, operation, eOpts){
							store.getProxy().extraParams = {
								'status': Ext.getCmp('filterActiveStatus').getValue(),
								'workflowStatus': Ext.getCmp('filterWorkflowStatus').getValue()
							};
						}
					}
				},				
				columns: [
					{ text: 'Entry Name', dataIndex: 'componentName', flex: 1},
					{ text: 'Version', dataIndex: 'version', align: 'center', width: 225 },
					{ text: 'Published', dataIndex: 'published', align: 'center', width: 175,
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{ text: 'Allow New Sections', dataIndex: 'allowNewSections', align: 'center', width: 175, hidden: true,
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{ text: 'Assigned Group', dataIndex: 'assignedGroup', align: 'center', width: 175 },					
					{ text: 'Assigned User', dataIndex: 'assignedUser', align: 'center', width: 175},
					{ text: 'Status', dataIndex: 'workflowStatus', align: 'center', width: 175,
						renderer: function(value, meta, record) {
							if (value === 'INPROGRESS') {
								meta.tdCls = 'alert-warning';
							} else if (value === 'WAIT') {
								meta.tdCls = 'alert-info';
							} else if (value === 'COMPLETE') {
								meta.tdCls = 'alert-success';
							} else if (value === 'HOLD') {
								meta.tdCls = 'alert-danager';
							}
							
							return record.get('workflowStatusDescription');
						}
					},					
					{ text: 'Create User', dataIndex: 'createUser', width: 175, hidden: true  },
					{ text: 'Update Date', dataIndex: 'updateDts', xtype: 'datecolumn', format:'m/d/y H:i:s',  width: 175 },
					{ text: 'Update User', dataIndex: 'updateUser', width: 175 }
				],
				listeners: {
					itemdblclick: function(grid, record, item, index, e, opts){
						actionAddEditQuestion(record);
					},						
					selectionchange: function(selModel, selected, opts) {
						var tools = Ext.getCmp('evaluationGrid').getComponent('tools');

						if (selected.length > 0) {	
							tools.getComponent('action').setDisabled(false);
							tools.getComponent('edit').setDisabled(false);	
							tools.getComponent('togglestatus').setDisabled(false);							
						} else {							
							tools.getComponent('action').setDisabled(true);
							tools.getComponent('edit').setDisabled(true);														
							tools.getComponent('togglestatus').setDisabled(true);
						}
						
						if (selected.length > 0 && selected[0].get('published')) {
							Ext.getCmp('publish').setDisabled(true);
							tools.getComponent('edit').setDisabled(true);
							Ext.getCmp('unpublish').setDisabled(false);
						} else {
							Ext.getCmp('publish').setDisabled(false);
							Ext.getCmp('unpublish').setDisabled(true);
						}
						
					}
				},				
				dockedItems: [
					{
						xtype: 'toolbar',
						dock: 'top',						
						items: [
							Ext.create('OSF.component.StandardComboBox', {
								id: 'filterActiveStatus',									
								emptyText: 'Active',
								value: 'A',
								fieldLabel: 'Active Status',
								name: 'activeStatus',									
								typeAhead: false,
								editable: false,
								width: 200,							
								listeners: {
									change: function(filter, newValue, oldValue, opts){
										actionRefresh();
									}
								},
								storeConfig: {
									customStore: {
										fields: [
											'code',
											'description'
										],
										data: [												
											{
												code: 'A',
												description: 'Active'
											},
											{
												code: 'I',
												description: 'Inactive'
											}
										]
									}
								}
							}),
							Ext.create('OSF.component.StandardComboBox', {
								id: 'filterWorkflowStatus',
								name: 'workflowStatus',								
								margin: '0 0 5 0',
								matchFieldWidth: false,
								editable: false,
								typeAhead: false,
								emptyText: 'All',
								minWidth: 200,	
								fieldLabel: 'Workflow Status',								
								storeConfig: {
									url: 'api/v1/resource/lookuptypes/WorkflowStatus',
									addRecords: [
										{
											code: null,
											description: 'All'
										}
									]
								},
								listeners: {
									change: function(filter, newValue, oldValue, opts){
										actionRefresh();
									}
								}			
							})
						]
					},					
					{
						dock: 'top',
						itemId: 'tools',
						xtype: 'toolbar',
						items: [
							{
								text: 'Refresh',
								iconCls: 'fa fa-2x fa-refresh icon-button-color-refresh icon-vertical-correction',
								scale: 'medium',
								width: '110px',
								handler: function(){
									actionRefresh();
								}
							},
							{
								xtype: 'tbseparator'
							},
							{
								text: 'Add',
								iconCls: 'fa fa-2x fa-plus icon-button-color-save icon-vertical-correction',
								scale: 'medium',
								handler: function(){
									addEditEvaluation();
								}
							},							
							{
								text: 'Edit',
								iconCls: 'fa fa-2x fa-edit icon-button-color-edit icon-vertical-correction-edit',
								itemId: 'edit',
								disabled: true,
								width: '100px',
								scale: 'medium',
								handler: function(){
									var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
									addEditEvaluation(record);
								}
							},
							{
								xtype: 'tbseparator'
							},
							{
								text: 'Toggle Staus',
								iconCls: 'fa fa-2x fa-power-off icon-button-color-default',
								itemId: 'togglestatus',
								disabled: true,									
								scale: 'medium',
								handler: function(){
									var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
									actionToggleStatus(record);
								}
							},
							{
								text: 'Action',
								itemId: 'action',
								disabled: true,									
								scale: 'medium',
								menu: [
									{
										text: 'Publish',
										id: 'publish',
										iconCls: 'fa fa-lg fa-book icon-button-color-save icon-small-vertical-correction',
										handler: function(){
											var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
											publish(record);
										}										
									},
									{
										text: 'Unpublish',
										id: 'unpublish',
										iconCls: 'fa fa-lg fa-ban icon-button-color-warning icon-small-vertical-correction',
										handler: function(){
											var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
											unpublish(record);
										}										
									},
									{
										xtype: 'menuseparator'
									},									
									{
										text: 'Copy',										
										iconCls: 'fa fa-lg fa-clone icon-button-color-default icon-small-vertical-correction',
										handler: function(){
											var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
											copy(record);
										}										
									},
									{
										xtype: 'menuseparator'
									},									
									{
										text: 'Assign Group',
										iconCls: 'fa fa-lg fa-users icon-button-color-default icon-small-vertical-correction',
										handler: function(){
											var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
											actionAssignGroup(record);
										}										
									},	
									{
										text: 'Assign User',
										iconCls: 'fa fa-lg fa-user icon-button-color-default icon-small-vertical-correction',
										handler: function(){
											var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
											actionAssignUser(record);
										}										
									},
									{
										text: 'Toggle Allow New Sections',
										iconCls: 'fa fa-lg fa-power-off icon-button-color-default icon-small-vertical-correction',
										handler: function(){
											var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
											actionAllowNewSections(record);
										}										
									},									
									{
										xtype: 'menuseparator'
									},
									{
										text: 'Delete',
										iconCls: 'fa fa-lg fa-trash icon-button-color-warning icon-small-vertical-correction',
										cls: 'alert-danger',
										handler: function(){
											var record = Ext.getCmp('evaluationGrid').getSelectionModel().getSelection()[0];
											actionDelete(record);
										}										
									}									
								]
							}								
						]
					},
					{
						xtype: 'pagingtoolbar',
						dock: 'bottom',
						store: 'evaluationGridStore',
						displayInfo: true
					}
				]				
			});
			
			addComponentToMainViewPort(evaluationGrid);	
			
			var actionRefresh = function(){
				evaluationGrid.getStore().reload();
			};
			
			var addEditEvaluation = function(record){
				
				if (record) {
					
					evaluationGrid.setLoading('Checking evaluation entry...');
					Ext.Ajax.request({
						url: 'api/v1/resource/evaluations/' + record.get('evaluationId') + '/checkentry',
						method: 'PUT',
						callback: function(){
							evaluationGrid.setLoading(false);
						},
						success: function(response, opts) {
							var evalformWin = Ext.create('OSF.component.EvaluationFormWindow', {
								title: 'Evaluation Form - ' + record.get('componentName')
							});
							evalformWin.show();
							
							var evaluation = Ext.decode(response.responseText);
							evalformWin.loadEval(record.get('evaluationId'), evaluation.componentId, function(){
								actionRefresh();
							});
							
							if (evaluation.componentId !== record.get('componentId')) {
								actionRefresh();
							}														
						}
					});					
				} else {
					createEvaluationWin.show();
					createEvaluationWin.getComponent('form').getComponent('workflowStatus').getStore().load();
					createEvaluationWin.getComponent('form').reset();
				}
			};
			
			var actionAssignGroup = function(record) {
				
				var assignWin = Ext.create('Ext.window.Window', {
					title: 'Assign Group',
					iconCls: 'fa fa-users',
					closeAction: 'destroy',
					modal: true,
					width: 400,
					height: 200,
					layout: 'fit',
					items: [
						{
							xtype: 'form',
							itemId: 'form',
							bodyStyle: 'padding: 10px;',
							layout: 'anchor',
							items: [
								{
									xtype: 'combobox',
									name: 'assignedGroup',
									fieldLabel: 'Assign to Group',
									displayField: 'description',
									valueField: 'code',								
									emptyText: 'Unassigned',
									labelAlign: 'top',
									width: '100%',
									editable: false,
									forceSelection: true,
									store: {									
										autoLoad: true,
										proxy: {
											type: 'ajax',
											url: 'api/v1/resource/securityroles/lookup'
										},
										listeners: {
											load: function(store, records, opts) {
												store.add({
													code: null,
													description: 'Unassigned'
												});
											}
										}
									}
								}	
							],
							dockedItems: [
								{
									xtype: 'toolbar',
									dock: 'bottom',
									items: [
										{
											text: 'Save',
											formBind: true,
											iconCls: 'fa fa-lg fa-save icon-button-color-save',
											handler: function() {
												var form = this.up('form');
												var formData = form.getValues();
												
												var data = record.data;
												
												data = Ext.apply(data, formData);
												
												CoreUtil.submitForm({
													url: 'api/v1/resource/evaluations/' + data.evaluationId,
													method: 'PUT',
													form: form,
													data: data,
													success: function(action, opts) {
														actionRefresh();
														assignWin.close();														
													}
												});
											}
										},
										{
											xtype: 'tbfill'
										},
										{
											text: 'Cancel',
											iconCls: 'fa fa-lg fa-close icon-button-color-warning',
											handler: function(){
												assignWin.close();
											}											
										}
									]
								}
							]
						}
					]
				});
				assignWin.show();
				
				assignWin.queryById('form').loadRecord(record);
				
			};

			var actionAssignUser = function(record) {

				var assignWin = Ext.create('Ext.window.Window', {
					title: 'Assign Group',
					iconCls: 'fa fa-user',
					closeAction: 'destroy',
					modal: true,
					width: 400,
					height: 200,					
					layout: 'fit',
					items: [
						{
							xtype: 'form',
							itemId: 'form',
							bodyStyle: 'padding: 10px;',
							layout: 'anchor',
							items: [
								{
									xtype: 'combobox',
									name: 'assignedUser',
									fieldLabel: 'Assign to User',
									displayField: 'description',
									valueField: 'code',								
									emptyText: 'Unassigned',
									labelAlign: 'top',
									width: '100%',
									editable: false,
									forceSelection: true,
									store: {									
										autoLoad: true,
										proxy: {
											type: 'ajax',
											url: 'api/v1/resource/userprofiles/lookup'
										},
										listeners: {
											load: function(store, records, opts) {
												store.add({
													code: null,
													description: 'Unassigned'
												});
											}
										}									
									}
								}
							],
							dockedItems: [
								{
									xtype: 'toolbar',
									dock: 'bottom',
									items: [
										{
											text: 'Save',
											formBind: true,
											iconCls: 'fa fa-lg fa-save icon-button-color-save',
											handler: function() {
												var form = this.up('form');
												var formData = form.getValues();
												
												var data = record.data;
												
												data = Ext.apply(data, formData);
												
												CoreUtil.submitForm({
													url: 'api/v1/resource/evaluations/' + data.evaluationId,
													method: 'PUT',
													form: form,
													data: data,
													success: function(action, opts) {
														actionRefresh();
														assignWin.close();														
													}
												});
											}
										},
										{
											xtype: 'tbfill'
										},
										{
											text: 'Cancel',
											iconCls: 'fa fa-lg fa-close icon-button-color-warning',
											handler: function(){
												assignWin.close();
											}											
										}
									]
								}
							]
						}
					]
				});
				assignWin.show();
				
				assignWin.queryById('form').loadRecord(record);		
		
			};
			
			var actionAllowNewSections = function(record) {
				evaluationGrid.setLoading('Updating evaluation...');
				Ext.Ajax.request({
					url: 'api/v1/resource/evaluations/' + record.get('evaluationId') + '/allownewsections',
					method: 'PUT',
					callback: function(){
						evaluationGrid.setLoading(false);
					},
					success: function(response, opts){
						actionRefresh();
					}
				});
			};

			var copy = function(record) {
				evaluationGrid.setLoading('Copying...');
				Ext.Ajax.request({
					url: 'api/v1/resource/evaluations/' + record.get('evaluationId') + '/copy',
					method: 'POST',
					callback: function(){
						evaluationGrid.setLoading(false);
					},
					success: function(response, opts){
						actionRefresh();
					}
				});	
			};

			var publish = function(record){
				Ext.Msg.show({
					title:'Publish Evaluation?',
					message: 'Are you sure you want to PUBLISH this evaluation?',
					buttons: Ext.Msg.YESNO,
					icon: Ext.Msg.QUESTION,
					fn: function(btn) {
						if (btn === 'yes') {
							evaluationGrid.setLoading('Publishing...');
							Ext.Ajax.request({
								url: 'api/v1/resource/evaluations/' + record.get('evaluationId') + '/publish',
								method: 'PUT',
								callback: function(){
									evaluationGrid.setLoading(false);
								},
								success: function(response, opts){
									actionRefresh();
								}
							});	
						} 
					}
				});				
			};

			var unpublish = function(record){
				Ext.Msg.show({
					title:'Unpublish Evaluation?',
					message: 'Are you sure you want to UNPUBLISH this evaluation?',
					buttons: Ext.Msg.YESNO,
					icon: Ext.Msg.QUESTION,
					fn: function(btn) {
						if (btn === 'yes') {
							evaluationGrid.setLoading('Publishing...');
							Ext.Ajax.request({
								url: 'api/v1/resource/evaluations/' + record.get('evaluationId') + '/unpublish',
								method: 'PUT',
								callback: function(){
									evaluationGrid.setLoading(false);
								},
								success: function(response, opts){
									actionRefresh();
								}
							});	
						} 
					}
				});				
			};

			var actionToggleStatus = function(record) {
				Ext.getCmp('evaluationGrid').setLoading("Updating Status...");
				var evaluationId = Ext.getCmp('evaluationGrid').getSelection()[0].get('evaluationId');
				var currentStatus = Ext.getCmp('evaluationGrid').getSelection()[0].get('activeStatus');

				var method = 'PUT';
				var urlEnd = '/activate';
				if (currentStatus === 'A') {
					method = 'DELETE';
					urlEnd = '';
				}					
				Ext.Ajax.request({
					url: 'api/v1/resource/evaluations/' + evaluationId + urlEnd,
					method: method,
					callback: function(){
						Ext.getCmp('evaluationGrid').setLoading(false);
					},
					success: function(response, opts){						
						actionRefresh();
					}
				});				
			};	
			
			var actionDelete = function(record) {
				Ext.Msg.show({
					title:'Delete Evaluation?',
					iconCls: 'fa fa-lg fa-warning icon-small-vertical-correction',
					message: 'Are you sure you want to delete this evaluation?',
					buttons: Ext.Msg.YESNO,
					icon: Ext.Msg.QUESTION,
					fn: function(btn) {
						if (btn === 'yes') {
							evaluationGrid.setLoading('Deleting...');
							Ext.Ajax.request({
								url: 'api/v1/resource/evaluations/' + record.get('evaluationId') + '?force=true',
								method: 'DELETE',
								callback: function(){
									evaluationGrid.setLoading(false);
								},
								success: function(response, opts){
									actionRefresh();
								}
							});	
						} 
					}
				});					
			};			
		
		});
		
	</script>

    </stripes:layout-component>
</stripes:layout-render>	