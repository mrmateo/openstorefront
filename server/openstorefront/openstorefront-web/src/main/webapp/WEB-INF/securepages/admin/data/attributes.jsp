<%--
/* 
 * Copyright 2016 Space Dynamics Laboratory - Utah State University Research Foundation.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * See NOTICE.txt for more information.
 */
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ taglib prefix="stripes" uri="http://stripes.sourceforge.net/stripes.tld" %>
<stripes:layout-render name="../../../../layout/toplevelLayout.jsp">
    <stripes:layout-component name="contents">

	<stripes:layout-render name="../../../../layout/adminheader.jsp">		
	</stripes:layout-render>
		
	<script src="scripts/component/importWindow.js?v=${appVersion}" type="text/javascript"></script>	

	<form name="exportForm" action="api/v1/resource/attributes/export" method="POST">
			<p style="display: none;" id="exportFormAttributeTypes"></p>      
	</form>
	
	<style type="text/css">
		
		.attribute-button-inactive,
		.attribute-button-active {

			width: 100%;
			border: 2px solid #E7E7E7;
			text-align: left;
			transition-duration: 0.4s;
			cursor: pointer;
			outline: none;
			color: #000000;
		}
		
		.attribute-button-inactive:hover,
		.attribute-button-active:hover {
			
			border-color: #B2B2B2;
		}

		.attribute-button-inactive span,
		.attribute-button-active span {

			display: inline-block;
			float: right;
			transition-duration: 0.4s;
		}

		.attribute-button-inactive span:before {

			content: '\02C3';
		}

		.attribute-button-active span:before {

			content: '\02C5';
		}

		.attribute-button-inactive {

			background-color: #FFFFFF;
		}

		.attribute-button-active {

			background-color: #EEEEEE;
		}

		.emboldened {

			font-weight: bold;
		}

		.attributes-visible,
		.attributes-hidden {

			margin: 0;
			padding: 2px 2px 2px 20px;
		}

		.attributes-visible {

			display: block;
		}

		.attributes-hidden {

			display: none;
		}
		
	</style>

	<script type="text/javascript">
		
		var displayAttributeList = function displayAttributeList(button, listId) {
				
			var attributes = document.getElementById(listId);

			if (button.className != "attribute-button-active")  {

				button.className = "attribute-button-active";

				attributes.className = "attributes-visible";
			}
			else {

				button.className = "attribute-button-inactive";

				attributes.className = "attributes-hidden";
			}
		};
		
		/* global Ext, CoreUtil */
		Ext.onReady(function() {


			var attributeStore = Ext.create('Ext.data.Store', {
				id: 'attributeStore',
				autoLoad: true,
				fields: [
					{ name: 'defaultAttributeCodeDisplay', mapping: function(data) {
						if (data.defaultAttributeCode) {
							return data.defaultAttributeCode;
						}
						return '';	
					}},
					{ name: 'allowUserGeneratedCodesDisplay', mapping: function(data) {
						if (data.allowUserGeneratedCodes) {
							return data.allowUserGeneratedCodes;
						}
						return false;
					}}
				],
				sorters: [
					new Ext.util.Sorter({
						property: 'description',
						direction: 'ASC'
					})
				],	
				proxy: {
					type: 'ajax',
					url: 'api/v1/resource/attributes/attributetypes?all=true',
					reader: {
						type: 'json',
						rootProperty: 'data'
					}
				}
			});
			
			
			var store_components_remote = Ext.create('Ext.data.Store', {
				storeId: 'store_components_remote',
				autoLoad: false,
				fields: [
					'name',
					'componentId',
					'componentType',
					'componentTypeDescription'
				],
				sorters: new Ext.util.Sorter({
					property: 'name',
					direction: 'ASC'
				}),
				proxy: {
					id: 'store_components_remoteProxy',
					type: 'ajax',
					url: 'api/v1/resource/components/'
				},
				listeners: {

					load: function(store, operation, opts) { // Once Data Store Has Loaded

						// Initialize Local Components Data Array
						var localComponents = [];

						// Loop Through Remote Components
						for (var i = 0; i < store.getCount(); i++) {

							// Initialize Current Component
							var currentComponent = {

								// Store Current Component ID
								id: store.getAt(i).data.componentId,

								// Store Current Component Name
								name: store.getAt(i).data.name,

								// Store Current Component Security Level
								type: {

									name: store.getAt(i).data.componentTypeDescription,
									code: store.getAt(i).data.componentType
								},
								
								// Initialize Attributes Array
								attributes: []
							};
							
							// Loop Through Component's Existing Attributes
							for (var j = 0; j < store.getAt(i).data.attributes.length; j++) {
								
								// Store Attribute
								currentComponent.attributes[j] = {
									
									// Store Attribute Name
									name: store.getAt(i).data.attributes[j].typeLabel,
									
									// Store Attribute Value
									value: store.getAt(i).data.attributes[j].label
								};
							}
							
//							console.log(store.getAt(i).data);

							// Store Component
							localComponents.push(currentComponent);
						}

						// Set Local Component Store Data
						store_components_local.setData(localComponents);
					}
				}					
			});

			var store_components_local = Ext.create('Ext.data.Store', {
				storeId: 'store_components_local',
				autoLoad: true,
				fields: [
					'id',
					'name',
					'type'
				],
				sorters: 'name'
			});

			var store_componentTypes_remote = Ext.create('Ext.data.Store', {
				storeId: 'store_componentTypes_remote',
				proxy: {
					type: 'ajax',
					url: 'api/v1/resource/componenttypes/lookup'
				},
				autoLoad: true
			});

			var store_assignedComponents_local = Ext.create('Ext.data.Store', {
				storeId: 'store_tagComponents_local',
				autoLoad: true,
				fields: [
					'id',
					'name',
					'type'
				],
				sorters: 'name'
			});
			
			
			///////////////
			// Overrides //
			///////////////

			Ext.override(Ext.view.DragZone, {
			    getDragText: function() {
			        if (this.dragTextField) {
			            var fieldValue = this.dragData.records[0].get(this.dragTextField);
			            return Ext.String.format(this.dragText, fieldValue);
			        } else {
			            var count = this.dragData.records.length;
			            return Ext.String.format(this.dragText, count, count == 1 ? '' : 's');
			        }
			    }
			});


			Ext.override(Ext.grid.plugin.DragDrop, {
			    onViewRender : function(view) {
			        var me = this;

			        if (me.enableDrag) {
			            me.dragZone = Ext.create('Ext.view.DragZone', {
			                view: view,
			                ddGroup: me.dragGroup || me.ddGroup,
			                dragText: me.dragText,
			                dragTextField: me.dragTextField
			            });
			        }

			        if (me.enableDrop) {
			            me.dropZone = Ext.create('Ext.grid.ViewDropZone', {
			                view: view,
			                ddGroup: me.dropGroup || me.ddGroup
			            });
			        }
			    }
			});

			///////////////////
			// End Overrides //
			///////////////////


			var gridColorRenderer = function gridColorRenderer(value, metadata, record) {
				if (value) 
					metadata.tdCls = 'alert-success';
				else 
					metadata.tdCls = 'alert-danger';
				return value;
			};


			var attributeGrid = Ext.create('Ext.grid.Panel', {
				id: 'attributeGrid',
				title: 'Manage Attributes <i class="fa fa-lg fa-question-circle"  data-qtip="Attributes are used to categorize components and other listings. They can be searched on and filtered. They represent the metadata for a listing. Attribute Types represent a category and a code represents a specific value. The data is linked by the type and code which allows for a simple change of the description."></i>',
				store: 'attributeStore',
				selModel: {
					selType: 'checkboxmodel'        
				},
				listeners: {
					selectionchange: function (grid, record, index, opts) {
						
						// Ensure Some Record Is Selected
						if (Ext.getCmp('attributeGrid').getSelectionModel().hasSelection()) {
							
							// Check If Only One Record Selected
							if (Ext.getCmp('attributeGrid').getSelectionModel().getCount() === 1) {
								
								// Enable Options (Single Selection)
								Ext.getCmp('attributeGrid-tools-edit').enable();
								Ext.getCmp('attributeGrid-tools-manageCodes').enable();
							}
							else {
								
								// Disable Options (Multiple Selections)
								Ext.getCmp('attributeGrid-tools-edit').disable();
								Ext.getCmp('attributeGrid-tools-manageCodes').disable();
							}
							
							// Enable Options (Any Selection)
							Ext.getCmp('attributeGrid-tools-action').enable();
							Ext.getCmp('attributeGrid-tools-export').enable();
						}
						else {
							
							// Disable Options (No Selection)
							Ext.getCmp('attributeGrid-tools-action').disable();
							Ext.getCmp('attributeGrid-tools-export').disable();
							Ext.getCmp('attributeGrid-tools-edit').disable();
							Ext.getCmp('attributeGrid-tools-manageCodes').disable();
						}
					}
				},
				columnLines: true,
				columns: [
					{text: 'Description', dataIndex: 'description', flex: 2},
					{text: 'Type Code', dataIndex: 'attributeType', flex: 1.5},
					{
						text: 'Required',
						dataIndex: 'requiredFlg',
						flex: 1, 
						tooltip: 'Is the attribute required upon adding a new component?',
						align: 'center',
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{
						text: 'Visible', 
						dataIndex: 'visibleFlg', 
						flex: 1, 
						tooltip: 'Show in the list of filters?',
						align: 'center',
						renderer: CoreUtil.renderer.booleanRenderer
					},					
					{
						text: 'Important',
						dataIndex: 'importantFlg',
						flex: 1, 
						tooltip: 'Shows on main page browse categories?',
						align: 'center',
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{
						text: 'Architecture',
						dataIndex: 'architectureFlg',
						flex: 1, 
						tooltip: 'Is the attribute an architecture?',
						align: 'center',
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{
						text: 'Allow Multiple',
						dataIndex: 'allowMultipleFlg',
						flex: 1, 
						tooltip: 'Should a component be allowed to have more than one code for this attribute?',
						align: 'center',
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{
						text: 'Allow User Codes',
						dataIndex: 'allowUserGeneratedCodesDisplay',
						flex: 1,
						tooltip: 'Should users be able to generate codes for this attribute?',
						align: 'center',
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{
						text: 'Hide On Submission',
						dataIndex: 'hideOnSubmission',
						flex: 1, 
						tooltip: 'Should the attribute type show on the submission form?',
						align: 'center',
						renderer: CoreUtil.renderer.booleanRenderer
					},
					{
						text: 'Default Code',
						dataIndex: 'defaultAttributeCodeDisplay',
						flex: 1
					},
					{
						text: 'Status',
						dataIndex: 'activeStatus',
						align: 'center',
						flex: 0.5
					}
				],
				dockedItems: [
					{
						dock: 'top',
						xtype: 'toolbar',
						items: [
							Ext.create('OSF.component.StandardComboBox', {
								id: 'attributeFilter-activeStatus',
								emptyText: 'Show All',
								fieldLabel: 'Active Status',
								name: 'activeStatus',
								listeners: {
									change: function (filter, newValue, oldValue, opts) {
										if (newValue === 'A') {
											attributeStore.filter('activeStatus','A');
										}
										else {
											attributeStore.filter('activeStatus', 'I');
										}
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
							})
						]
					},
					{
						xtype: 'toolbar',
						dock: 'top',
						items: [
							{
								text: 'Refresh',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-refresh icon-button-color-refresh icon-vertical-correction',
								handler: function () {
									attributeStore.load();
								}
							},
							{ 
								xtype: 'tbseparator'
							},
							{
								text: 'Add New Type',
								id: 'attributeGrid-tools-add',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-plus icon-button-color-save',
								handler: function() {
									actionAddAttribute();
								}
							},							
							{
								text: 'Edit Attribute',
								id: 'attributeGrid-tools-edit',
								scale: 'medium',
								width: '150px',
								disabled: true,
								iconCls: 'fa fa-2x fa-edit icon-button-color-edit icon-vertical-correction-edit',
								handler: function() {
									var record = attributeGrid.getSelection()[0];
									actionEditAttribute(record);
								}
							},
							{
								text: 'Manage Codes',
								id: 'attributeGrid-tools-manageCodes',
								scale: 'medium',
								width: '160px',
								disabled: true,
								iconCls: 'fa fa-2x fa-list-alt icon-vertical-correction-edit icon-button-color-default',
								handler: function() {
									var record = attributeGrid.getSelection()[0];
									actionManageCodes(record);
								}
							},
							{
								xtype: 'tbseparator'
							}, 
							{
								text: 'Entry Assignment',
								id: 'attributeGrid-tools-assign',
								hidden: true,
								scale: 'medium',
								iconCls: 'fa fa-2x fa-list-alt icon-vertical-correction-edit icon-button-color-default',
								handler: function() {
									actionManageAssignments();
								}
							},
							{
								text: 'Action',
								id: 'attributeGrid-tools-action',
								scale: 'medium',																	
								disabled: true,
								iconCls: 'fa fa-2x fa-gear icon-vertical-correction icon-button-color-default',
								menu: [
									{
										text: 'Set Flags',
										id: 'attributeGrid-tools-action-flags',
										iconCls: 'fa fa-lg fa-flag icon-small-vertical-correction icon-button-color-default',
										handler: function() {
											
											// Check If Only One Record Selected
											if (attributeGrid.getSelectionModel().getCount() === 1) {

												var title = "'" + attributeGrid.getSelection()[0].get('description') + "'";
											}
											else {

												var title = attributeGrid.getSelectionModel().getCount() + ' Attributes';
											}
											
											// Configure Window Title
											setFlagsWin.setTitle('Set Flags - ' + title);
											
											// Display Window
											setFlagsWin.show();
										}
									},
									{
										xtype: 'menuseparator'
									},
									{
										text: 'Toggle Status',
										id: 'attributeGrid-tools-action-toggle',
										iconCls: 'fa fa-lg fa-power-off icon-small-vertical-correction icon-button-color-default',
										handler: function() {
											
											actionToggleAttributeStatus();
										}
									},
									{
										text: 'Delete',
										id: 'attributeGrid-tools-action-delete',
										cls: 'alert-danger',
										iconCls: 'fa fa-lg fa-trash icon-button-color-default icon-small-vertical-correction',
										handler: function() {
											
											actionDeleteAttribute();
										}
									}
								]
							},
							{
								xtype: 'tbfill'
							},
							{
								text: 'Import',
								id: 'attributeGrid-tools-import',
								hidden: true,
								scale: 'medium',
								iconCls: 'fa fa-2x fa-upload icon-button-color-default icon-vertical-correction',
								handler: function() {
									actionImportAttribute();
								}
							},
							{
								text: 'Export',
								id: 'attributeGrid-tools-export',
								hidden: true,
								scale: 'medium',
								disabled: true,
								iconCls: 'fa fa-2x fa-download icon-button-color-default',
								handler: function() {
									var records = attributeGrid.getSelection();
									actionExportAttribute(records);
								}
							}
						]
					}
				]
			});
			
			CoreService.userservice.getCurrentUser().then(function(user){
				if (CoreService.userservice.userHasPermisson(user, "ADMIN-ENTRY-MANAGEMENT")) {
					Ext.getCmp('attributeGrid-tools-assign').setHidden(false);					
				}
				if (CoreService.userservice.userHasPermisson(user, "ADMIN-DATA-IMPORT-EXPORT")) {
					Ext.getCmp('attributeGrid-tools-import').setHidden(false);
					Ext.getCmp('attributeGrid-tools-export').setHidden(false);
				}				
			});			
			

			var actionAddAttribute = function actionAddAttribute() {
				Ext.getCmp('editAttributeForm').reset();
				editAttributeWin.edit = false;
				editAttributeWin.setTitle('<i class="fa fa-plus"></i>' + '<span class="shift-window-text-right">Add Attribute</span>');
				editAttributeWin.show();
				Ext.getCmp('editAttributeForm-code').setEditable(true);
				Ext.getCmp('editAttributeForm-defaultCode').hide();
				Ext.getCmp('editAttributeForm-hideOnSubmission').disable();
				Ext.getCmp('editAttributeForm-typesRequiredFor').getStore().removeAll();
				Ext.getCmp('editAttributeForm-associatedComponentTypes').getStore().removeAll();
			};
			
			
			var actionManageAssignments = function() {
				
				// Display Assignment Management Window
				manageAssignmentsWin.show();
			};


			var actionEditAttribute = function(record) {
				editAttributeWin.edit = true;
				editAttributeWin.setTitle('<i class="fa fa-edit icon-horizontal-correction-right"></i>' + ' ' + '<span class="shift-window-text-right">Edit Attribute - </span>' + record.data.attributeType);
				editAttributeWin.show();
				
				Ext.getCmp('editAttributeForm-defaultCode').setValue(null);
				Ext.getCmp('allEntryTypes').setValue(true);
				Ext.getCmp('requiredFlagCheckBox').setValue(false);
				Ext.getCmp('editAttributeForm-typesRequiredFor').getStore().removeAll();
				Ext.getCmp('editAttributeForm-associatedComponentTypes').getStore().removeAll();
				Ext.getCmp('editAttributeForm').reset();
				
				Ext.getCmp('editAttributeForm').loadRecord(record);

		
				var requiredEntryTypes = Ext.getCmp('editAttributeForm-typesRequiredFor').getStore();
				// Search the searchStore for the record matching the given code,
				// that way we can display the name of the entry type rather than
				// just the code.
				if (record.getData().requiredRestrictions) {
					Ext.getCmp('requiredFlagCheckBox').setValue(true);
					var searchStore = Ext.getStore('requiredTypesSearchStore');
					Ext.Array.each(record.getData().requiredRestrictions, function(type) {
						requiredEntryTypes.add(searchStore.getData().find('code', type.componentType));
					});
				}

				// And the same for the associated component types, as well as disabling the 'All' checkbox.
				if (record.getData().associatedComponentTypes) {
					Ext.getCmp('allEntryTypes').setValue(false);
					var associatedComponentTypes = Ext.getCmp('editAttributeForm-associatedComponentTypes').getStore();
					var allowForTypesSearchStore = Ext.getStore('allowForTypesSearchStore');
					Ext.Array.each(record.getData().associatedComponentTypes , function(type) {
						associatedComponentTypes.add(allowForTypesSearchStore.getData().find('code', type.componentType));
					});
				} 

				Ext.getCmp('editAttributeForm-defaultCode').show();
				Ext.getCmp('editAttributeForm-hideOnSubmission').enable();
				Ext.getCmp('editAttributeForm-code').setEditable(false);
				// Retreive codes to populate form options
				var url = 'api/v1/resource/attributes/attributetypes/';
				url += record.data.attributeType;
				url += '/attributecodeviews';
				Ext.getCmp('editAttributeForm-defaultCode').setStore({
					autoLoad: true,
					proxy: {
						type: 'ajax',
						url: url,
						reader: {
							type: 'json',
							rootProperty: 'data'
						}
					},
					listeners: {
						load: function(store, records) {
							store.add({
								code: null,
								label: 'Select'
							});
						}
					}
				});
				
			};
			
			var setFlagsWin_DisableUpdate = function() {
				
				// Initialize Update Button Enabled Value
				var enable = false;
				
				// Check Radio Groups
				if (Ext.getCmp('set-flags-visible-group').getValue().visible !== null) {
					
					// Enable Update Button
					enable = true;
				}
//				else if (Ext.getCmp('set-flags-required-group').getValue().required !== null) {
//					
//					// Enable Update Button
//					enable = true;
//				}
				else if (Ext.getCmp('set-flags-important-group').getValue().important !== null) {
					
					// Enable Update Button
					enable = true;
				}
				else if (Ext.getCmp('set-flags-architecture-group').getValue().architecture !== null) {
					
					// Enable Update Button
					enable = true;
				}
				else if (Ext.getCmp('set-flags-multiples-group').getValue().multiples !== null) {
					
					// Enable Update Button
					enable = true;
				}
				else if (Ext.getCmp('set-flags-user-group').getValue().user !== null) {
					
					// Enable Update Button
					enable = true;
				}
				else if (Ext.getCmp('set-flags-hide-group').getValue().hide !== null) {
					
					// Enable Update Button
					enable = true;
				}
				
				// Check If Update Button Should Be Enabled
				if (enable) {
					
					// Enable Update Button
					Ext.getCmp('set-flags-update-button').enable();
				}
				else {
					
					// Disable Update Button
					Ext.getCmp('set-flags-update-button').disable();
				}
			};
			
			var setFlagsWin = Ext.create('Ext.window.Window', {
				
				id: 'setFlagsWin',
				title: 'Set Flags - ',
				iconCls: 'fa fa-lg fa-flag',
				width: '35%',
				y: 200,
				modal: true,
				layout: 'fit',					
				items: [
					{
						xtype: 'form',
						itemId: 'setFlagsForm',
						bodyStyle: 'padding: 10px',
						items: [
							
							{
								xtype: 'radiogroup',
								id: 'set-flags-visible-group',
								fieldLabel: 'Visible',
								labelAlign: 'top',
								width: '100%',
								columns: 3,
								margin: '0 0 10 0',
								items: [
									{boxLabel: 'True', name: 'visible', inputValue: true, formItemCls: 'x-form-item alert-success', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'False', name: 'visible', inputValue: false, formItemCls: 'x-form-item alert-danger', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'No Change', name: 'visible', inputValue: null, checked: true, formItemCls: 'x-form-item alert-warning', style: 'display: block; padding-left: 5px;'}
								],
								listeners: {
									
									change: setFlagsWin_DisableUpdate
								}
							},
//							{
//								xtype: 'radiogroup',
//								id: 'set-flags-required-group',
//								fieldLabel: 'Required',
//								labelAlign: 'top',
//								width: '100%',
//								columns: 3,
//								margin: '0 0 10 0',
//								items: [
//									{boxLabel: 'True', name: 'required', inputValue: true, formItemCls: 'x-form-item alert-success', style: 'display: block; padding-left: 5px;'},
//									{boxLabel: 'False', name: 'required', inputValue: false, formItemCls: 'x-form-item alert-danger', style: 'display: block; padding-left: 5px;'},
//									{boxLabel: 'No Change', name: 'required', inputValue: null, checked: true, formItemCls: 'x-form-item alert-warning', style: 'display: block; padding-left: 5px;'}
//								],
//								listeners: {
//									
//									change: setFlagsWin_DisableUpdate
//								}
//							},
							{
								xtype: 'radiogroup',
								id: 'set-flags-important-group',
								fieldLabel: 'Important',
								labelAlign: 'top',
								width: '100%',
								columns: 3,
								margin: '0 0 10 0',
								items: [
									{boxLabel: 'True', name: 'important', inputValue: true, formItemCls: 'x-form-item alert-success', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'False', name: 'important', inputValue: false, formItemCls: 'x-form-item alert-danger', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'No Change', name: 'important', inputValue: null, checked: true, formItemCls: 'x-form-item alert-warning', style: 'display: block; padding-left: 5px;'}
								],
								listeners: {
									
									change: setFlagsWin_DisableUpdate
								}
							},
							{
								xtype: 'radiogroup',
								id: 'set-flags-architecture-group',
								fieldLabel: 'Architecture',
								labelAlign: 'top',
								width: '100%',
								columns: 3,
								margin: '0 0 10 0',
								items: [
									{boxLabel: 'True', name: 'architecture', inputValue: true, formItemCls: 'x-form-item alert-success', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'False', name: 'architecture', inputValue: false, formItemCls: 'x-form-item alert-danger', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'No Change', name: 'architecture', inputValue: null, checked: true, formItemCls: 'x-form-item alert-warning', style: 'display: block; padding-left: 5px;'}
								],
								listeners: {
									
									change: setFlagsWin_DisableUpdate
								}
							},
							{
								xtype: 'radiogroup',
								id: 'set-flags-multiples-group',
								fieldLabel: 'Allow Multiples <i class="fa fa-lg fa-question-circle" data-qtip="\'Required\' and \'Allow Multiples\' are mutually exclusive. If \'Allow Multiples\' is not available, then your selection contains some attributes that are already flagged as \'Required\'.  Delete the \'Required\' attributes from your selection to bulk edit \'Allow Multiples\'."></i>',
								labelAlign: 'top',
								width: '100%',
								columns: 3,
								margin: '0 0 10 0',
								items: [
									{boxLabel: 'True', id: 'set-flags-multiples-group-true', name: 'multiples', inputValue: true, formItemCls: 'x-form-item alert-success', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'False', id: 'set-flags-multiples-group-false', name: 'multiples', inputValue: false, formItemCls: 'x-form-item alert-danger', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'No Change', id: 'set-flags-multiples-group-none', name: 'multiples', inputValue: null, checked: true, formItemCls: 'x-form-item alert-warning', style: 'display: block; padding-left: 5px;'}
								],
								listeners: {
									
									change: setFlagsWin_DisableUpdate
								}
							},
							{
								xtype: 'radiogroup',
								id: 'set-flags-user-group',
								fieldLabel: 'Allow User Codes',
								labelAlign: 'top',
								width: '100%',
								columns: 3,
								margin: '0 0 10 0',
								items: [
									{boxLabel: 'True', name: 'user', inputValue: true, formItemCls: 'x-form-item alert-success', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'False', name: 'user', inputValue: false, formItemCls: 'x-form-item alert-danger', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'No Change', name: 'user', inputValue: null, checked: true, formItemCls: 'x-form-item alert-warning', style: 'display: block; padding-left: 5px;'}
								],
								listeners: {
									
									change: setFlagsWin_DisableUpdate
								}
							},
							{
								xtype: 'radiogroup',
								id: 'set-flags-hide-group',
								fieldLabel: 'Hide On Submission',
								labelAlign: 'top',
								width: '100%',
								columns: 3,
								margin: '0 0 10 0',
								items: [
									{boxLabel: 'True', name: 'hide', inputValue: true, formItemCls: 'x-form-item alert-success', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'False', name: 'hide', inputValue: false, formItemCls: 'x-form-item alert-danger', style: 'display: block; padding-left: 5px;'},
									{boxLabel: 'No Change', name: 'hide', inputValue: null, checked: true, formItemCls: 'x-form-item alert-warning', style: 'display: block; padding-left: 5px;'}
								],
								listeners: {
									
									change: setFlagsWin_DisableUpdate
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
										id: 'set-flags-update-button',
										formBind: true,
										iconCls: 'fa fa-lg fa-save icon-button-color-save',
										disabled: true,
										handler: function() {

											// Get Selection
											var selection = Ext.getCmp('attributeGrid').getSelection();

											// Get Number Of Selected
											var selected = attributeGrid.getSelectionModel().getCount();

											// Get Calling Window
											var ownerWindow = this.up('window');

											// Get Form
											var form = this.up('form');

											// Inform User Of Update Process
											attributeGrid.mask('Updating Flag(s)...');

											// Close Form Window
											ownerWindow.close();
											
											// Store New Values
											var attributeValues = form.getForm().getValues();

											// Initialize Update Counter
											var attributeUpdateCount = 0;

											// Loop Through Selected Components
											for (i = 0; i < selected; i++) {
												
												// Save Record Data
												var attributeData = selection[i].getData();
												
												// Initialize Request Data
												var requestData = {
													
													attributeType: attributeData,
													componentTypeRestrictions: [],
													associatedComponentTypes: []
												};
												
												// Check Required For Components
												if (typeof attributeData.requiredRestrictions !== 'undefined' && attributeData.requiredRestrictions !== null) {
													
													// Store Required For Components
													requestData.componentTypeRestrictions = attributeData.requiredRestrictions;
												}
												
												// Check Associated Components
												if (typeof attributeData.associatedComponentTypes !== 'undefined' && attributeData.associatedComponentTypes !== null) {
													
													// Store Associated Components
													requestData.associatedComponentTypes = attributeData.associatedComponentTypes;
												}
												
												//////////////////
												// Update Flags //
												//////////////////
												
												// Check For Visible
												if (typeof attributeValues.visible !== 'undefined' && attributeValues.visible !== null) {

													// Set New Flag Value
													requestData.attributeType.visibleFlg = attributeValues.visible;
												}
												
//												// Check For Required
//												if (typeof attributeValues.required !== 'undefined' && attributeValues.required !== null) {
//
//													// Set New Flag Value
//													requestData.attributeType.requiredFlg = attributeValues.required;
//												}
												
												// Check For Important
												if (typeof attributeValues.important !== 'undefined' && attributeValues.important !== null) {

													// Set New Flag Value
													requestData.attributeType.importantFlg = attributeValues.important;
												}
												
												// Check For Architecture
												if (typeof attributeValues.architecture !== 'undefined' && attributeValues.architecture !== null) {

													// Set New Flag Value
													requestData.attributeType.architectureFlg = attributeValues.architecture;
												}
												
												// Check For Allow Multiples
												if (typeof attributeValues.multiples !== 'undefined' && attributeValues.multiples !== null) {

													// Set New Flag Value
													requestData.attributeType.multiplesFlg = attributeValues.multiples;
												}
												
												// Check For Allow User Codes
												if (typeof attributeValues.user !== 'undefined' && attributeValues.user !== null) {

													// Set New Flag Value
													requestData.attributeType.allowUserGeneratedCodes = attributeValues.user;
												}
												
												// Check For Hide On Submission
												if (typeof attributeValues.hide !== 'undefined' && attributeValues.hide !== null) {

													// Set New Flag Value
													requestData.attributeType.hideOnSubmission = attributeValues.hide;
												}
												
												// Reset Flags Form
												form.reset();
												console.log(requestData);
												// Make Request
												Ext.Ajax.request({

													url: 'api/v1/resource/attributes/attributetypes/' + attributeData.attributeType,
													method: 'PUT',
													jsonData: requestData,
													success: function(response, opts) {

														// Check If We Are On The Final Request
														if (++attributeUpdateCount === selected) {

															// Provide Success Notification
															Ext.toast('All Attributes Have Been Processed', 'Success');

															// Refresh Store
															attributeStore.load();

															// Unmask Grid
															attributeGrid.unmask();
														}
													},
													failure: function(response, opts) {

														// Provide Error Notification
														Ext.toast('An Attribute Failed To Update', 'Error');

														// Provide Log Information
														console.log(response);

														// Check If We Are On The Final Request
														if (++attributeUpdateCount === selected) {

															// Provide Success Notification
															Ext.toast('All Attributes Have Been Processed', 'Success');

															// Refresh Store
															attributeStore.load();

															// Unmask Grid
															attributeGrid.unmask();
														}
													}
												});
											}
										}
									},
									{
										xtype: 'tbfill'
									},
									{
										text: 'Cancel',
										iconCls: 'fa fa-lg fa-close icon-button-color-warning',
										handler: function(){
											this.up('window').close();
										}
									}
								]
							}
						]
					}
				],
				listeners: {
					
					activate: function() {
						
						// Disable Update Button
						// (For Some Reason, Setting It As Disabled Had No Effect)
						Ext.getCmp('set-flags-update-button').disable();
						
						
						// Get Selection
						var selection = attributeGrid.getSelection();
						
						// Get Number Selected
						var selected = attributeGrid.getSelectionModel().getCount();
						
						// Loop Through Selected
						for (i = 0; i < selected; i++) {
							
							// Check For Required
							if (selection[i].getData().requiredFlg) {
								
								// Disable Allow Multiples
								Ext.getCmp('set-flags-multiples-group-true').disable();
								Ext.getCmp('set-flags-multiples-group-false').disable();
								Ext.getCmp('set-flags-multiples-group-none').disable();
								
								// Mask Fields
								Ext.getCmp('set-flags-multiples-group-true').mask();
								Ext.getCmp('set-flags-multiples-group-false').mask();
								Ext.getCmp('set-flags-multiples-group-none').mask();
								
								// Stop Looping
								return;
							}
						}
						
						// Enable Allow Multiples
						// (Loop Didn't Prematurely End)
						Ext.getCmp('set-flags-multiples-group-true').enable();
						Ext.getCmp('set-flags-multiples-group-false').enable();
						Ext.getCmp('set-flags-multiples-group-none').enable();
						
						// Unmask Fields
						Ext.getCmp('set-flags-multiples-group-true').unmask();
						Ext.getCmp('set-flags-multiples-group-false').unmask();
						Ext.getCmp('set-flags-multiples-group-none').unmask();
					}
				}
			});

			var actionToggleAttributeStatus = function actionToggleAttributeStatus() {
				
				// Store Selection
				var selection = attributeGrid.getSelection();
				
				// Store Selected
				var selected = attributeGrid.getSelectionModel().getCount();
				
				// Inform User Of Update Process
				attributeGrid.mask('Toggling Status...');
				
				// Initialize Update Counter
				var attributeToggleCount = 0;
				
				// Loop Through Selected
				for (i = 0; i < selected; i++) {
					
					// Store Record
					var record = selection[i];
					
					// Define URL
					var url = 'api/v1/resource/attributes/attributetypes/' + record.data.attributeType;
					
					// Check If Record Is Active
					if (record.data.activeStatus === 'A') {
						
						// Set HTTP Method
						var method = 'DELETE';
					}
					else {
						
						// Set HTTP Method
						var method = 'POST';
					}
					
					// Make Request
					Ext.Ajax.request({
						
						url: url,
						method: method,
						success: function(response, opts) {
							console.log(response);
							// Check If We Are On The Final Request
							if (++attributeToggleCount === selected) {
								
								new Ext.util.DelayedTask(function() {
									
									// Provide Success Notification
									Ext.toast('All Attributes Have Been Processed', 'Success');

									// Refresh Store
									attributeStore.load();

									// Unmask Grid
									attributeGrid.unmask();
									
								}).delay(2000);
							}
						},
						failure: function(response, opts) {

							// Provide Error Notification
							Ext.toast('An Attribute Failed To Toggle', 'Error');

							// Provide Log Information
							console.log(response);

							// Check If We Are On The Final Request
							if (++attributeToggleCount === selected) {

								// Provide Success Notification
								Ext.toast('All Attributes Have Been Processed', 'Success');

								// Refresh Store
								attributeStore.load();

								// Unmask Grid
								attributeGrid.unmask();
							}
						}
					});
				}
			};

			var actionDeleteAttribute = function actionDeleteAttribute() {
				
				// Get Selection
				var selection = Ext.getCmp('attributeGrid').getSelection();

				// Get Number Of Selected
				var selected = attributeGrid.getSelectionModel().getCount();

				// Check If Only One Record Selected
				if (selected === 1) {

					var name = "'" + selection[0].get('description') + "'";
				}
				else {

					var name = selected + ' Attributes';
				}
				
				// Confirm Delete Operation
				Ext.Msg.show({
					iconCls: 'fa fa-lg fa-warning icon-small-vertical-correction',
					title: 'Delete Attribute?',
					minHeight: 180,
					message: '<b>Are you sure you want to delete attribute - ' + name + '?</b><br /><br /><b>Note:</b> This will remove the attribute from ALL entries approved and <br />&emsp;&emsp;&emsp;not approved.',
					buttons: Ext.Msg.YESNO,
					icon: Ext.Msg.QUESTION,
					fn: function(btn) {

						if (btn === 'yes') {
							
							// Inform User Of Update Process
							attributeGrid.mask('Deleting...');

							// Initialize Update Counter
							var attributeDeleteCount = 0;

							// Loop Through Selection
							for (i = 0; i < selected; i++) {

								// Store Record
								var record = selection[i];
								
								// Define URL
								var url = 'api/v1/resource/attributes/attributetypes/' + record.data.attributeType + '/force';
								
								// Make Request
								Ext.Ajax.request({
									
									url: url,
									method: 'DELETE',
									success: function(response, opts) {

										// Check If We Are On The Final Request
										if (++attributeDeleteCount === selected) {

											new Ext.util.DelayedTask(function() {
									
												// Provide Success Notification
												Ext.toast('All Attributes Have Been Processed', 'Success');

												// Refresh Store
												attributeStore.load();

												// Unmask Grid
												attributeGrid.unmask();

											}).delay(2000);
										}
									},
									failure: function(response, opts) {

										// Provide Error Notification
										Ext.toast('An Attribute Failed To Delete', 'Error');

										// Provide Log Information
										console.log(response);

										// Check If We Are On The Final Request
										if (++attributeDeleteCount === selected) {

											// Provide Success Notification
											Ext.toast('All Attributes Have Been Processed', 'Success');

											// Refresh Store
											attributeStore.load();

											// Unmask Grid
											attributeGrid.unmask();
										}
									}
								});
							}
						}
					}
				});
			};

			var actionImportAttribute = function actionImportAttribute() {
				importWindow.show();
			};

			var actionExportAttribute = function actionExportAttribute(records) {
				
				// Initialize Export Types
				var attributeTypes = "";
				
				// Loop Through Records
				Ext.Array.each(records, function(record) {
					
					// Add Attribute Type To Form
					attributeTypes += '<input type="hidden" name="type" ';
					attributeTypes += 'value="' + record.get('attributeType') +'" />';
				});
				
				// Get CSRF Token From Cookie
				var token = Ext.util.Cookies.get('X-Csrf-Token');

				// Ensure CSRF Token Is Available
				if (token) {

					// Add CSRF Token To Form
					attributeTypes += '<input type="hidden" name="X-Csrf-Token" ';
					attributeTypes += 'value="' + token + '" />';
				}
				
				// Set Form
				document.getElementById('exportFormAttributeTypes').innerHTML = attributeTypes;
				
				// Submit Form
				document.exportForm.submit();
			};

			var importWindow = Ext.create('OSF.component.ImportWindow', {					
				fileTypeReadyOnly: false,
				fileTypeValue: 'ATTRIBUTE',	
				uploadSuccess: function(form, action) {
					Ext.getCmp('attributeGrid').getStore().reload();
				}
			});

			var actionManageCodes = function actionManageCodes(record) {
				var url = 'api/v1/resource/attributes/attributetypes';
				url += '/' + record.data.attributeType + '/attributecodeviews?all=true';
				codesStore.setProxy({
					type: 'ajax',
					url: url,
					reader: {
						type: 'json',
						rootProperty: 'data'
					}
				});
				codesStore.filter('activeStatus', 'A');
				codesStore.load();
				manageCodesWin.attributeType = record.data.attributeType;
				Ext.getCmp('codesFilter-activeStatus').setValue('A');
				
				manageCodesWin.show();
			};


			var attachmentUploadWindow = Ext.create('Ext.window.Window', {
				id: 'attachmentUploadWindow',
				title: 'Add Attachment',
				iconCls: 'fa fa-lg fa-paperclip',
				width: '40%',
				height: 175,
				y: 60,
				modal: true,
				maximizable: false,
				bodyStyle : 'padding: 10px;',
				layout: 'fit',
				items: [
					{
						xtype: 'form',
						id: 'attachmentUploadForm',
						layout: 'vbox',
						defaults: {
							labelAlign: 'top',
							width: '100%'
						},
						items: [
							{
								xtype: 'filefield',
								name: 'uploadFile',
								width: '100%',
								allowBlank: false,
								fieldLabel: 'Choose a file to upload<span class="field-required" />',
								buttonText: 'Select File...',
								listeners: {
									change: CoreUtil.handleMaxFileLimit
								}
							}
						]
					}
				],
				dockedItems: [
					{
						xtype: 'toolbar',
						dock: 'bottom',
						items: [
							{
								text: 'Upload Attachment',
								iconCls: 'fa fa-lg fa-upload icon-button-color-default',
								formBind: true,	
								handler: function() {
									var record = Ext.getCmp('codesGrid').getSelection()[0];
									var parentAttributeRecord = attributeGrid.getSelection()[0];
									var attributeTypeName = parentAttributeRecord.get('attributeType');
									var attributeCodeName = record.get('code');
									var form = Ext.getCmp('attachmentUploadForm');
									var url = '/openstorefront/Upload.action?AttributeCodeAttachment';
									url += '&attributeTypeName=' + attributeTypeName;
									url += '&attributeCodeName=' + attributeCodeName;
									if (form.isValid()) {
										form.submit({
											url: url,
											waitMsg: 'Uploading file...',
											success: function () {
												Ext.toast('Successfully uploaded attachment.', '', 'tr');
												attachmentUploadWindow.hide();
												codesStore.load();
											},
											failure: function () {
												Ext.toast('Failed to upload attachment.');
											}
										});
									}
								}
							},
							{
								xtype: 'tbfill'
							},
							{
								text: 'Cancel',
								iconCls: 'fa fa-lg fa-close icon-button-color-warning',
								handler: function () {
									Ext.getCmp('attachmentUploadWindow').hide();
								}
							}
						]
					}
				]

			});

			var codesStore = Ext.create('Ext.data.Store', {
				id: 'codesStore'
			});

			var codesGrid = Ext.create('Ext.grid.Panel', {
				id: 'codesGrid',
				columnLines: true,
				store: codesStore,
				scrollable: true,
				autoScroll: true,
				listeners: {
					selectionchange: function (grid, record, index, opts) {
						if (Ext.getCmp('codesGrid').getSelectionModel().hasSelection()) {
							Ext.getCmp('codesGrid-tools-edit').enable();
							Ext.getCmp('codesGrid-tools-toggle').enable();
							Ext.getCmp('codesGrid-tools-delete').enable();
							Ext.getCmp('codesToolbarAddAttachment').enable();
							if (record[0].data.activeStatus === 'A') {
								Ext.getCmp('codesGrid-tools-toggle').setText('Toggle Status');
							}
							else {
								Ext.getCmp('codesGrid-tools-toggle').setText('Toggle Status');
							}
							var attachment = record[0].get('attachmentFileName');
							if (!attachment) {
								Ext.getCmp('codesToolbarDownloadAttachment').disable();
								Ext.getCmp('codesToolbarDeleteAttachment').disable();
								Ext.getCmp('codesToolbarAddAttachment').setText('Add Attachment');
							}
							else {
								Ext.getCmp('codesToolbarDownloadAttachment').enable();
								Ext.getCmp('codesToolbarDeleteAttachment').enable();
								Ext.getCmp('codesToolbarAddAttachment').setText('Replace Attachment');
							}
						} else {
							Ext.getCmp('codesGrid-tools-edit').disable();
							Ext.getCmp('codesGrid-tools-toggle').disable();
							Ext.getCmp('codesGrid-tools-delete').disable();
							Ext.getCmp('codesToolbarDownloadAttachment').disable();
							Ext.getCmp('codesToolbarDeleteAttachment').disable();
							Ext.getCmp('codesToolbarAddAttachment').disable();
							Ext.getCmp('codesToolbarAddAttachment').setText('Add Attachment');
						}
					}
				},
				dockedItems: [
					{
						dock: 'top',
						xtype: 'toolbar',
						items: [
							Ext.create('OSF.component.StandardComboBox', {
								id: 'codesFilter-activeStatus',
								emptyText: 'Active',
								fieldLabel: 'Active Status',
								name: 'activeStatus',
								listeners: {
									change: function (filter, newValue, oldValue, opts) {
										if (newValue === 'A') {
											codesStore.filter('activeStatus','A');
										}
										else if (newValue === 'I') {
											codesStore.filter('activeStatus', 'I');
										}
										else {
											codesStore.clearFilter();
										}
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
							})
						]
					},
					{
						xtype: 'toolbar',
						dock: 'top',
						items: [
							{
								text: 'Refresh',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-refresh icon-button-color-refresh icon-vertical-correction',
								handler: function () {
									codesStore.load();
								}
							},
							{
								xtype: 'tbseparator'
							},
							{
								text: 'Add New Code',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-plus icon-button-color-save',
								handler: function () {
									var parentAttributeRecord = attributeGrid.getSelection()[0];
									actionAddCode(parentAttributeRecord);
								}
							},
							{
								text: 'Edit Code',
								id: 'codesGrid-tools-edit',
								scale: 'medium',
								width: '140px',
								iconCls: 'fa fa-2x fa-edit icon-button-color-edit icon-vertical-correction-view',
								disabled: true,
								handler: function () {
									var record = codesGrid.getSelection()[0];
									actionEditCode(record);
								}
							},
							{
								xtype: 'tbseparator'
							},
							{
								text: 'Toggle Status',
								id: 'codesGrid-tools-toggle',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-power-off icon-button-color-default icon-vertical-correction',
								disabled: true,
								handler: function () {
									var record = codesGrid.getSelection()[0];
									actionToggleCode(record);
								}
							},
							{
								text: 'Delete',
								id: 'codesGrid-tools-delete',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-trash icon-button-color-warning icon-vertical-correction',
								disabled: true,
								handler: function () {
									var record = codesGrid.getSelection()[0];
									var title = 'Delete Attribute Code?';
									var msg = '<b>Are you sure you want to delete this attribute code?</b><br /><br /><b>Note: </b>This will delete ALL attributes with this code from all<br />&emsp;&emsp;&emsp; approved and not approved entries.';
									Ext.MessageBox.confirm(title, msg, function (btn) {
										if (btn === 'yes') {
											actionDeleteCode(record);
										}
									});
								}
							},
							{
								xtype: 'tbfill'
							},
							{
								text: 'Add Attachment',
								disabled: true,
								id: 'codesToolbarAddAttachment',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-paperclip icon-vertical-correction icon-button-color-default',
								handler: function() {
									Ext.getCmp('attachmentUploadWindow').show();
								}
							},
							{
								text: 'Download Attachment',
								disabled: true,
								id: 'codesToolbarDownloadAttachment',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-download icon-button-color-default',
								handler: function() {
									var codeRecord = codesGrid.getSelection()[0];
									var typeRecord = attributeGrid.getSelection()[0];
									var type = typeRecord.get('attributeType');
									var code = codeRecord.get('code');
									var url = 'api/v1/resource/attributes/attributetypes/';
									url += type;
									url += '/attributecodes/' + code;
									url += '/attachment';
									window.location.href = url;		
								}
							},
							{
								xtype: 'tbseparator'
							},
							{
								text: 'Delete Attachment',
								disabled: true,
								id: 'codesToolbarDeleteAttachment',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-trash icon-button-color-warning icon-vertical-correction',
								handler: function() {
									var record = codesGrid.getSelection()[0];
									var title = '<i class="fa fa-warning icon-horizontal-correction-right"></i>' + ' ' + '<span class="shift-window-text-right">Delete Attachment?</span>';
									var msg = 'Are you sure you want to delete the attachment for this code?';
									Ext.MessageBox.confirm(title, msg, function (btn) {
										if (btn === 'yes') {
											actionDeleteCodeAttachment(record);
										}
									});
								}
							}
						]
					}
				],
				columns: [
					{text: 'Label', dataIndex: 'label', flex: 2},
					{
						text: 'Code',
						dataIndex: 'code',
						flex: 1
					},
					{
						text: 'Description', 
						dataIndex: 'description', 
						flex: 3,
						cellWrap: true
					},
					{
						text: 'Highlight Style',
						dataIndex: 'highlightStyle',
						flex: 1,
						renderer: function (value, metadata, record) {
							var classColor = 'alert-' + value;
							metadata.tdCls = classColor;
							return value;
						}
					},
					{text: 'Attachment', dataIndex: 'attachmentFileName', flex: 2},
					{text: 'Link', dataIndex: 'detailUrl', flex: 1, hidden: true},
					{text: 'Group Code', dataIndex: 'groupCode', flex: 1, hidden: true},
					{text: 'Sort Order', dataIndex: 'sortOrder', flex: 1, hidden: true},
					{text: 'Architecture Code', dataIndex: 'architectureCode', flex: 1.5, hidden: true},
					{text: 'Badge URL', dataIndex: 'badgeUrl', flex: 1},
					{ text: 'Security Marking',  dataIndex: 'securityMarkingDescription', width: 150, hidden: !${branding.allowSecurityMarkingsFlg} }
				]
			});

			var highlightStyleStore = Ext.create('Ext.data.Store', {
				fields: ['highlightStyle'],
				data: [
					{'highlightStyle': 'info'},
					{'highlightStyle': 'success'},
					{'highlightStyle': 'warning'},
					{'highlightStyle': 'danger'},
					{'highlightStyle': 'inverse'},
					{'highlightStyle': 'default'}
				]
			});
			
			var mediaWindow = Ext.create('OSF.component.MediaInsertWindow', {
				
				isEditor: false,
				mediaSelectionUrl: 'api/v1/resource/generalmedia',
				closeAction: 'hide',
				mediaHandler: function(link) {

					Ext.getCmp('editCodeForm').getForm().setValues({ badgeUrl: encodeURI(link) });
				}
			});

			var editCodeWin = Ext.create('Ext.window.Window', {
				id: 'editCodeWin',
				title: 'Add/Edit Code Win',
				modal: true,
				width: '60%',
				height: '90%',
				autoScroll: true,
				y: '2em',
				layout: 'fit',
				items: [
					{
						xtype: 'form',
						id: 'editCodeForm',
						scrollable: true,
						layout: 'anchor',
						autoScroll: true,
						bodyStyle: 'padding: 10px;',
						defaults: {
							labelAlign: 'top',
							width: '100%'
						},
						items: [
							{
								xtype: 'textfield',
								id: 'editCodeForm-label',
								fieldLabel: 'Label<span class="field-required" />',
								name: 'label'
							},
							{
								xtype: 'textfield',
								id: 'editCodeForm-code',
								fieldLabel: 'Type Code<span class="field-required" />',
								name: 'typeCode'
							},
							{
								xtype: 'panel',
								html: '<b>Description</b>'
							},
							{
								xtype: 'tinymce_textarea',
								fieldStyle: 'font-family: Courier New; font-size: 12px;',
								style: {border: '0'},
								name: 'description',
								width: '100%',
								height: 300,
								maxLength: 4096,
								tinyMCEConfig: CoreUtil.tinymceConfig()
							},
							{
								xtype: 'textfield',
								fieldLabel: 'Detail URL',
								name: 'detailUrl'
							},
							{
								xtype: 'textfield',
								fieldLabel: 'Group Code',
								name: 'groupCode'
							},
							{
								xtype: 'textfield',
								fieldLabel: 'Sort Order',
								name: 'sortOrder'
							},
							{
								xtype: 'textfield',
								fieldLabel: 'Architecture Code',
								name: 'architectureCode'
							},
							{
								xtype: 'label',
								text: 'Badge URL:',
								style: {
									fontWeight: 'bold'
								}
							},
							{
								layout: 'hbox',
								margin: '5px 0 0 0',
								items: [
									{
										xtype: 'textfield',
										name: 'badgeUrl',
										flex: 4
									},
									{
										xtype: 'button',
										text: 'Insert Media',
										flex: 1,
										handler: function() {
											
											mediaWindow.show();
										}
									}
								]
							},
							{
								xtype: 'combobox',
								fieldLabel: 'Highlight Style',
								displayField: 'highlightStyle',
								valueField: 'highlightStyle',
								name: 'highlightStyle',
								store: highlightStyleStore,
								typeAhead: false,
								editable: false
							},
							Ext.create('OSF.component.SecurityComboBox', {	
								hidden: !${branding.allowSecurityMarkingsFlg}
							})					
						]
					}
				],
				dockedItems: [
							{
								xtype: 'toolbar',
								dock: 'bottom',
								items: [
									{
										text: 'Save',
										id: 'editCodeWin-save',
										iconCls: 'fa fa-lg fa-save icon-button-color-save',
										formBind: true,
										handler: function () {
											var form = Ext.getCmp('editCodeForm');
											if (form.isValid()) {
												var formData = form.getValues();
												var edit = editCodeWin.edit;
												var attributeType = editCodeWin.attributeType;
												var url = 'api/v1/resource/attributes/attributetypes/';
												url += attributeType + '/attributecodes';

												var method = 'POST';
												var data = {};
												data = formData;
												if (edit) {
													url += '/' + formData.typeCode;
													method = 'PUT';
												}
												else {
													data.attributeCodePk = {};
													data.attributeCodePk.attributeType = attributeType;
													data.attributeCodePk.attributeCode = data.typeCode;
												}

												
												CoreUtil.submitForm({
													url: url,
													method: method,
													data: data,
													removeBlankDataItems: true,
													form: Ext.getCmp('editCodeForm'),
													success: function (response, opts) {
														Ext.toast('Saved Successfully', '', 'tr');
														codesStore.load();
														Ext.getCmp('editCodeForm').reset();
														editCodeWin.hide();
													},
													failure: function (response, opts) {
														Ext.toast('Failed to save', '', 'tr');
													}
												});



											}
										}
									},
									{
										xtype: 'tbfill'
									},
									{
										text: 'Cancel',
										iconCls: 'fa fa-lg fa-close icon-button-color-warning',
										handler: function () {
											Ext.getCmp('editCodeForm').reset();
											editCodeWin.close();
										}
									}
								]
							}
						]
			});

			var actionAddCode = function actionAddCode(parentAttributeRecord) {
				Ext.getCmp('editCodeForm').reset();
				editCodeWin.edit = false;
				editCodeWin.attributeType = parentAttributeRecord.data.attributeType;
				editCodeWin.setTitle('<i class="fa fa-plus"></i>' + '<span class="shift-window-text-right">Add New Code</span>');
				Ext.getCmp('editCodeForm-code').setEditable(true);
				editCodeWin.show();
			};

			var actionEditCode = function actionEditCode(record) {
				Ext.getCmp('editCodeForm').loadRecord(record);
				Ext.getCmp('editCodeForm-code').setValue(record.data.code);
				editCodeWin.edit = true;
				editCodeWin.attributeType = manageCodesWin.attributeType;
				editCodeWin.setTitle('<i class="fa fa-edit"></i>' + '<span class="shift-window-text-right">Edit Code - </span>' + record.data.code);
				Ext.getCmp('editCodeForm-code').setEditable(false);
				editCodeWin.show();
			};

			var actionToggleCode = function acitionToggleCode(record) {
				var url = 'api/v1/resource/attributes/attributetypes/';
				url += manageCodesWin.attributeType;
				url += '/attributecodes/' + record.data.code;
				if (record.data.activeStatus === 'A') {
					var what = 'deactivate';
					var method = 'DELETE';
				}
				else {
					var what = 'activate';
					var method = 'POST';
				}
				Ext.Ajax.request({
					url: url,
					method: method,
					success: function(response, opt){
						Ext.toast('Successfully ' + what + 'd attribute code', '', 'tr');
						codesStore.load();
					},
					failure: function(response, opt){
						Ext.toast('Failed to ' + what + ' attribute code', '', 'tr');
					}
				});
			};

			var actionDeleteCode = function acitionDeleteCode(record) {
				var url = 'api/v1/resource/attributes/attributetypes/';
				url += manageCodesWin.attributeType;
				url += '/attributecodes/' + record.data.code;
				url += '/force';
				var method = 'DELETE';
				Ext.Ajax.request({
					url: url,
					method: method,
					success: function(response, opt){
						Ext.toast('Successfully sent deletion request for attribute code', '', 'tr');
						codesStore.load();
					},
					failure: function(response, opt){
						Ext.toast('Failed to send deletion request for attribute code', '', 'tr');
					}
				});

			};

			var actionDeleteCodeAttachment = function acitionDeleteCode(record) {
				var url = 'api/v1/resource/attributes/attributetypes/';
				url += manageCodesWin.attributeType;
				url += '/attributecodes/' + record.data.code;
				url += '/attachment';
				var method = 'DELETE';
				Ext.Ajax.request({
					url: url,
					method: method,
					success: function(response, opt){
						Ext.toast('Successfully deleted attachment', '', 'tr');
						codesStore.load();
					},
					failure: function(response, opt){
						Ext.toast('Failed to delete attachment', '', 'tr');
					}
				});

			};


			var manageCodesWin = Ext.create('Ext.window.Window', {
				id: 'manageCodesWin',
				iconCls: 'fa fa-2x fa-list-alt',
				title: 'Manage Codes',
				iconCls: 'fa fa-lg fa-list-alt icon-small-vertical-correction',
				modal: true,
				width: '90%',
				height: '90%',
				maximizable: true,
				y: '2em',
				layout: 'fit',
				items: [
					codesGrid
				]
			});


			var editAttributeWin = Ext.create('Ext.window.Window', {
				id: 'editAttributeWin',
				title: 'Add/Edit Attribute',
				modal: true,
				width: '60%',
				height: '80%',
				maximizable: true,
				y: '2em',
				layout: 'fit',
				items: [
					{
						xtype: 'form',
						id: 'editAttributeForm',
						autoScroll: true,
						bodyStyle: 'padding: 10px;',
						defaults: {
							labelAlign: 'top',
							width: '100%'
						},
						items: [
							{
								xtype: 'textfield',
								id: 'editAttributeForm-label',
								fieldLabel: 'Label<span class="field-required" />',
								allowBlank: false,
								name: 'description'
							},
							{
								xtype: 'textfield',
								id: 'editAttributeForm-code',
								fieldLabel: 'Type Code<span class="field-required" />',
								allowBlank: false,
								name: 'attributeType'
							},
							{
								xtype: 'combobox',
								fieldLabel: 'Default Code',
								id: 'editAttributeForm-defaultCode',
								displayField: 'label',
								valueField: 'code',
								typeAhead: false,
								editable: false,
								value: '',
								name: 'defaultAttributeCode',
								hidden: true
							},
							{
								xtype: 'panel',
								html: '<b>Detailed Description</b>'
							},
							{
								xtype: 'tinymce_textarea',
								fieldStyle: 'font-family: Courier New; font-size: 12px;',
								style: {border: '0'},
								name: 'detailedDescription',
								width: '100%',
								height: 300,
								maxLength: 255,
								tinyMCEConfig: CoreUtil.tinymceConfig()
							},
							{
								xtype: 'panel',
								html: '<b>Associated Entry Types:</b>'
							},
							{
								xtype: 'checkboxfield',
								id: 'allEntryTypes',
								boxLabel: 'Allow For All Entry Types',
								value: true,
								handler: function(box, value) {
									if (value) {
										Ext.getCmp('editAttributeForm-associatedComponentTypes').hide();
									} else {
										Ext.getCmp('editAttributeForm-associatedComponentTypes').show();
									}
								}
							},
							{
								xtype: 'multiselector',
								id: 'editAttributeForm-associatedComponentTypes',
								hidden: true,
								title: 'Allow this attribute for these entry types: (click plus icon to add)',
								name: 'associatedComponentTypes',
								fieldName: 'description',
								fieldTitle: 'Entry Type',
								viewConfig: {
									deferEmptyText: false,
									emptyText: 'No entry types selected. If no entry types are selected, all entries will allow this attribute.'
								},
								search: {
									id: 'allowForTypesSearch',
									field: 'description',
									bodyStyle: 'background: white;',
									store: Ext.create('Ext.data.Store', {
										id: 'allowForTypesSearchStore',
										proxy: {
											type: 'ajax',
											url: 'api/v1/resource/componenttypes/lookup'												
										},
										autoLoad: true
									})
								}
							},
							{
								xtype: 'panel',
								html: '<b>Flags:</b>'
							},
							{
								xtype: 'fieldcontainer',
								layout: 'hbox',
								defaultType: 'checkboxfield',
								defaultLayout: '100%',
								defaults: {
									flex: 1
								},
								items: [
									{
										name: 'requiredFlg',
										id: 'requiredFlagCheckBox',
										boxLabel: 'Required',
										listeners: {
											change: function(reqBox, newValue) {
												if (newValue)
													{
														Ext.getCmp('editAttributeForm-typesRequiredFor').show();

														var select = Ext.getCmp('editAttributeForm-defaultCode');
														if (Ext.getCmp('editAttributeForm-hideOnSubmission').getValue()) {
															select.setFieldLabel('Default Code<span class="field-required" />');
															select.allowBlank = false;
														} else {
															select.setFieldLabel('Default Code');
															select.allowBlank = true;
															select.clearInvalid();
														}

														var mult = Ext.getCmp('multipleFlagCheckBox');
														if (mult.getValue() == true) {
															var msg = 'Attributes that allow multiple codes cannot be required. You may delete the';
															msg += " 'allow multiple' flag, or keep the multiple codes flag and not set the required flag.";
															Ext.MessageBox.show({
																title: 'Attributes Allowing Multiple Codes Cannot Be Required',
																msg: msg,
																buttonText: {yes: "Delete 'Allow Multiple' Flag", no: "Keep 'Allow Multiple' Flag"},
																fn: function(btn) {
																	if (btn === 'yes') {
																		mult.setValue('false');
																	} else if (btn === 'no') {
																		reqBox.setValue('false');
																	}
																}
															});	
														}
													}
													else {
														Ext.getCmp('editAttributeForm-typesRequiredFor').hide();
														var select = Ext.getCmp('editAttributeForm-defaultCode');
														select.setFieldLabel('Default Code');
														select.allowBlank = true;
														select.clearInvalid();
													}
											}
										}
									},
									{
										name: 'visibleFlg',
										boxLabel: 'Visible'
									},
									{
										name: 'importantFlg',
										boxLabel: 'Important'
									},
									{
										name: 'architectureFlg',
										boxLabel: 'Architecture'
									},
									{
										name: 'allowMultipleFlg',
										id: 'multipleFlagCheckBox',
										boxLabel: 'Allow Multiple',
										listeners: {
											change: function(multiple, newValue) {
												if (newValue === true) {
													var rf = Ext.getCmp('requiredFlagCheckBox')
													if (rf.getValue() == true) {
														var msg = 'Attributes that are required are not allowed to have multiple codes. You may either';
														msg += ' delete the required flag, or keep the required flag and not allow multiple codes.'
														Ext.MessageBox.show({
															title: 'Required Attributes Cannot Have Multiple Codes',
															msg: msg,
															buttonText: {yes: "Delete Required Flag", no: "Keep Required Flag"},
															fn: function(btn) {
																if (btn === 'yes') {
																	rf.setValue('false');
																} else if (btn === 'no') {
																	multiple.setValue('false');
																}
															}
														});	
													}
												}
											}
										}
									},
									{
										name: 'allowUserGeneratedCodes',
										boxLabel: 'Allow User-Created Codes'
									},
									{
										name: 'hideOnSubmission',
										boxLabel: 'Hide on Submission',
										id: 'editAttributeForm-hideOnSubmission',
										toolTip: 'Hiding a required attribute requires a default code. Codes must be created before this flag can be set.',
										listeners: {
											change: function(box, newValue) {
												var select = Ext.getCmp('editAttributeForm-defaultCode');
												if (newValue === true && Ext.getCmp('requiredFlagCheckBox').getValue()) {
													select.setFieldLabel('Default Code<span class="field-required" />');
													select.allowBlank = false;
												}
												else {
													select.setFieldLabel('Default Code');
													select.allowBlank = true;
													select.clearInvalid();
												}
												var form = Ext.getCmp('editAttributeForm');
												form.getForm().checkValidity();
											}
										}
									}
								]
							},
							{
								xtype: 'multiselector',
								id: 'editAttributeForm-typesRequiredFor',
								hidden: true,
								title: 'Require this attribute for these entry types: (click plus icon to add)',
								name: 'typesRequiredFor',
								fieldName: 'description',
								fieldTitle: 'Entry Type',
								viewConfig: {
									deferEmptyText: false,
									emptyText: 'No entry types selected. If no entry type is selected, all entries will require this attribute.'
								},
								search: {									
									field: 'description',
									bodyStyle: 'background: white;',
									store: Ext.create('Ext.data.Store', {
										id: 'requiredTypesSearchStore',
										proxy: {
											type: 'ajax',
											url: 'api/v1/resource/componenttypes/lookup'												
										},
										autoLoad: true
									})
								}
							},
						],
						dockedItems: [
							{
								xtype: 'toolbar',
								dock: 'bottom',
								items: [
									{
										text: 'Save',
										id: 'editAttributeWin-save',
										iconCls: 'fa fa-lg fa-save icon-button-color-save',
										formBind: true,
										handler: function () {
											var form = Ext.getCmp('editAttributeForm');
											if (form.isValid()) {
												
												// Get Form Data
												// [asString], [dirtyOnly], [includeEmptyText], [useDataValues]
												var formData = form.getValues();
																								
												// Build Request
												var edit = editAttributeWin.edit;
												var url = 'api/v1/resource/attributes/attributetypes';
												var method = 'POST';
												if (edit) {
													url += '/' + formData.attributeType;
													method = 'PUT';
												}

												// Modify formData to exist inside AttributeSaveType
												var data = {};
												data.attributeType = formData;

												// If we have a set of entry types for which this attribute is associated,
												// compile them into the consumption format.
												if (!Ext.getCmp('allEntryTypes').getValue()) { // If box is NOT checked, include the entry type associations.
													var associatedTypes = Ext.getCmp('editAttributeForm-associatedComponentTypes').getStore().getData().getValues('code','data');

													data.associatedComponentTypes = [];

													Ext.Array.each(associatedTypes, function(type) {
														data.associatedComponentTypes.push({
															componentType: type
														});		
													});
												}


												// If we have a set of entry types for which this attribute is required,
												// compile them into the consumption format.
												if (formData.requiredFlg) {
													var restrictedTypes = Ext.getCmp('editAttributeForm-typesRequiredFor').getStore().getData().getValues('code','data');

													data.componentTypeRestrictions = [];

													Ext.Array.each(restrictedTypes, function(type) {
														data.componentTypeRestrictions.push({
															componentType: type
														});		
													});
												}
												
												CoreUtil.submitForm({
													url: url,
													method: method,
													data: data,
													removeBlankDataItems: false,
													form: Ext.getCmp('editAttributeForm'),
													success: function (response, opts) {
														Ext.toast('Saved Successfully', '', 'tr');
														attributeStore.load();
														Ext.getCmp('editAttributeForm').reset();
														editAttributeWin.hide();
													},
													failure: function (response, opts) {
														Ext.toast('Failed to save', '', 'tr');
													}
												});


											}
										}
									},
									{
										xtype: 'tbfill'
									},
									{
										text: 'Cancel',
										iconCls: 'fa fa-lg fa-close icon-button-color-warning',
										handler: function () {
											Ext.getCmp('editAttributeForm').reset();
											Ext.getCmp('editAttributeWin').hide();
										}
									}
								]
							}
						]
					}
				]
			});
			
			
			var refreshEntryGridPanels = function() {
				
				// Mask Component Grids (Loading)
				Ext.getCmp('unassignedComponentGrid').getView().mask("Loading...");
				Ext.getCmp('assignedComponentGrid').getView().mask("Loading...");

				// Store Attribute Type
				var type = Ext.getCmp('manageAssignmentsForm-attribute').getSelection().get('attributeType');

				// Store Attribute Code
				var code = Ext.getCmp('manageAssignmentsForm-code').getSelection().get('code');

				// Get Currently Assigned Components
				var url = 'api/v1/resource/attributes/attributetypes/' + type + '/attributecodes/' + code + '/components';

				Ext.Ajax.request({
					url: url,
					method: 'GET',
					success: function(response, opt) {

						// Parse Response JSON
						var components = JSON.parse(response.responseText);

						// Initialize Component ID Array
						var componentIds = [];

						// Initialize Component Data Array
						var componentData = [];

						// Loop Through Components
						for (i = 0; i < components.length; i++) {

							// Add Component ID To Array
							componentIds.push(components[i].componentId);
						}
						
						// Load Remote Components Store
						store_components_remote.load(function(records, operation, success) {
							
							// Clear Any Previous Filters
							store_components_local.clearFilter();

							// Filter Unassigned Components Store
							store_components_local.filterBy(function(record) {

								return !Ext.Array.contains(componentIds, record.get('id'));
							});
							
							// Loop Through Assigned Component IDs
							for (i = 0; i < componentIds.length; i++) {
								
								// Locate & Store Component With Matching ID
								var component = store_components_local.getById(componentIds[i]);
								
								// Check For Match
								if (component != null) {
								
									// Add Matching Component's Data To Array
									componentData.push(component.getData());
								}
							}

							// Add Assigned Component Data To Assigned Component Store
							store_assignedComponents_local.setData(componentData);

							// Unmask Component Grids (Loading)
							Ext.getCmp('unassignedComponentGrid').getView().unmask();
							Ext.getCmp('assignedComponentGrid').getView().unmask();
						});
					},
					failure: function(response, opt) {

						// Unmask Component Grids (Loading)
						Ext.getCmp('unassignedComponentGrid').getView().unmask();
						Ext.getCmp('assignedComponentGrid').getView().unmask();

						// Indicate An Error Occurred
						Ext.toast('Error Loading Entries', '', 'tr');

						// Log Response
						console.log('Error Loading Entries. See Response:');
						console.log(response);
					}
				});
			};
			
			
			var unassignedComponentGrid = Ext.create('Ext.grid.Panel', {
				id: 'unassignedComponentGrid',
				store: store_components_local,
				flex: 1,
				border: false,
				autoScroll: true,
				disabled: true,
				viewConfig: {

					plugins: {

						ptype: 'gridviewdragdrop',
						dragGroup: 'componentAssignment-add-drag-drop-group',
						dropGroup: 'componentAssignment-remove-drag-drop-group',
						enableDrag: true,
						enableDrop: true,
						dragText: 'Add: {0}',
						dragTextField: 'name'
					},
					listeners: {

						drop: function (node, data, overModel, dropPosition, eOpts) {

							// Store Component Data
							var component = data.records[0];
							var componentData = component.getData();
							
							// Store Attribute Type
							var type = Ext.getCmp('manageAssignmentsForm-attribute').getSelection().get('attributeType');
							var name = Ext.getCmp('manageAssignmentsForm-attribute').getSelection().get('description');

							// Store Attribute Code
							var code = Ext.getCmp('manageAssignmentsForm-code').getSelection().get('code');
							var value = Ext.getCmp('manageAssignmentsForm-code').getSelection().get('label');

							// Make Request
							Ext.Ajax.request({

								url: 'api/v1/resource/components/' + componentData.id + '/attributes/' + type + '/' + code,
								method: 'DELETE',
								success: function (response, opts) {
									
									// Loop Through Component Attributes
									for (i = 0; i < componentData.attributes.length; i++) {
										
										// Look For Matching Attribute
										if (componentData.attributes[i].name === name &&
												componentData.attributes[i].value === value) {
											
											// Delete Attribute
											componentData.attributes.splice(i, 1);
											
											// Stop Looping
											break;
										}
									}
									
									// Update Data Display
									unassignedComponentGrid.getView().refresh();
									
									// Clear Filters
									store_components_local.clearFilter();
									
									// Get Assigned Components
									var assignedComponents = store_assignedComponents_local.getData();
									
									// Initialize Assigned Component ID Array
									var assignedComponentIDs = [];
									
									// Loop Through Assigned Components
									for (i = 0; i < assignedComponents.length; i++) {
										
										// Add ID To Array
										assignedComponentIDs.push(assignedComponents.items[i].id);
									}
									
									// Filter Unassigned Components Store
									store_components_local.filterBy(function(record) {

										return !Ext.Array.contains(assignedComponentIDs, record.get('id'));
									});
									
									// Indicate Successful Removal
									Ext.toast("Attribute Deleted From " + componentData.name, '', 'tr');
								},
								failure: function (response, opts) {

									// Provide An Error Message
									Ext.toast("Error Deleting Attribute From " + componentData.name, '', 'tr');
									
									// Log Error
									console.log("Error Removing Attribute. See Response:");
									console.log(response);
									
									// Return Component To Previous Grid
									store_assignedComponents_local.addSorted(component);
									
									// Select Component
									assignedComponentGrid.getSelectionModel().select(component);
									
									// Send Focus Temporarily Elsewhere
									unassignedComponentGrid.focus();
									
									// Focus On Component
									assignedComponentGrid.getView().focusRow(component);
									
									// Remove Component From New Grid
									store_components_local.remove(component);
								}
							});
						}
					}
				},
				columns: [
					{ 
						text: 'Entries',
						dataIndex: 'name',
						flex: 1,
						renderer: function (value, metaData, record) {
							
							var html = '<span style="font-weight: bold;">' + value + "</span>";
							html += '<div style="color: #999; margin: 1em 0; padding: 0 0 0.75em 0;">';
							html += '<i class="fa fa-book icon-small-vertical-correction-book fa-fw" style="float:left; margin-right: 2px;"></i> ';
							html += '<span style="float: left;">' + record.get('type').name + '</span>';
							html += "</div>";
							
							html += '<div>';
							html += '	<button class="attribute-button-inactive" onclick="javascript:displayAttributeList(this, \'attributes_' + record.get('id') + '\')">Existing Attributes <span></span></button>';
							html += '	<ul id="attributes_' + record.get('id') + '" class="attributes-hidden">';
							
							for (var i = 0; i < record.get('attributes').length; i++) {
								
								html += '		<li>';
								html += '			<span class="emboldened">' + record.get('attributes')[i].name + ': </span>';
								html += '			' + record.get('attributes')[i].value;
								html += '		</li>';
							}
							
							html += '	</ul>';
							html += '</div>';
							
							return html;
						}

					}
				],
				dockedItems: [
					{
						xtype: 'toolbar',
						dock: 'top',
						items: [
							{
								text: 'Refresh',
								scale: 'medium',
								iconCls: 'fa fa-2x fa-refresh icon-button-color-refresh icon-vertical-correction',
								handler: function () {

									// Refresh Entry Grid Panels
									// (Also Performs A Store Reload)
									refreshEntryGridPanels();
								}
							}
						]
					},
					{
						xtype: 'toolbar',
						dock: 'top',
						items: [
							{
								xtype: 'tagfield',
								fieldLabel: 'Entry Types',
								labelWidth: new Ext.util.TextMetrics().getWidth("Entry Types:"),
								flex: 1,
								store: store_componentTypes_remote,
								valueField: 'code',
								displayField: 'description',
								emptyText: 'All',
								listeners: {
									change: function (tagfield, newValue, oldValue, eOpts) {

										// Get Current Filters On Store
										var filters = store_components_local.getFilters();

										// Loop Through Filters
										for (i = 0; i < filters.length; i++) {

											// Store Filter Function
											var filterFunction = filters.items[i].getFilterFn().toString();

											// Check If Current Filter Contains A String Which Itentifies This Filter
											if (filterFunction.search(/FILTER_BY_TYPE_CODE/) != -1) {

												// Remove Previous Filter
												store_components_local.removeFilter(filters.items[i]);
											}
										}

										// Check If We Should Create A Filter
										if (newValue.length > 0) {

											// Create A Filter
											store_components_local.filterBy(filter = function multiFilter(record) {

												// Identify Filter
												var filterName = "FILTER_BY_TYPE_CODE";

												// Locate Matching Records
												return Ext.Array.contains(newValue, record.get('type').code);
											});
										}
									}
								}
							}
						]
					},
					{
						xtype: 'toolbar',
						dock: 'top',
						items: [
							{
								xtype: 'textfield',
								flex: 1,
								fieldLabel: 'Filter',
								labelWidth: new Ext.util.TextMetrics().getWidth("Filter:"),
								listeners: {
									change: {

										buffer: 500,
										fn: function (field, newValue, oldValue, eOpts) {

											// Get Field's Store
											var store = Ext.getCmp("unassignedComponentGrid").getStore();

											// Get Current Filters On Store
											var filters = store.getFilters();

											// Loop Through Filters
											for (i = 0; i < filters.length; i++) {

												// Check If Current Filter Contains A String Which Itentifies This Filter
												if (filters.items[i].getFilterFn().toString().search(/FILTER_BY_NAME/) != -1) {

													// Remove Previous Filter
													store.removeFilter(filters.items[i]);
												}
											}

											// Set Filter
											store.filterBy(function(record) {

												// Identify Filter
												var filterName = "FILTER_BY_NAME";

												// Return Whether Search String Was Found
												return record.get('name').search(new RegExp(newValue, 'i')) != -1;
											});
										}
									}
								}
							}
						]
					}
				]
			});
			
			
			var assignedComponentGrid = Ext.create('Ext.grid.Panel', {
				flex: 1,
				id: 'assignedComponentGrid',
				store: store_assignedComponents_local,
				border: false,
				autoScroll: true,
				disabled: true,
				emptyText: 'No Assigned Entries',
				viewConfig: {

					plugins: {

						ptype: 'gridviewdragdrop',
						dragGroup: 'componentAssignment-remove-drag-drop-group',
						dropGroup: 'componentAssignment-add-drag-drop-group',
						enableDrag: true,
						enableDrop: true,
						dragText: 'Delete: {0}',
						dragTextField: 'name'
					},
					listeners: {

						drop: function (node, data, overModel, dropPosition, eOpts) {

							// Store Component Data
							var component = data.records[0];
							var componentData = component.getData();
							
							// Store Attribute Type
							var type = Ext.getCmp('manageAssignmentsForm-attribute').getSelection().get('attributeType');
							var name = Ext.getCmp('manageAssignmentsForm-attribute').getSelection().get('description');

							// Store Attribute Code
							var code = Ext.getCmp('manageAssignmentsForm-code').getSelection().get('code');
							var value = Ext.getCmp('manageAssignmentsForm-code').getSelection().get('label');

							// Build New Component Attribute Data
							var attributeData = {

								componentAttributePk: {

									attributeType: type,
									attributeCode: code
								}
							};

							// Make Request
							Ext.Ajax.request({

								url: 'api/v1/resource/components/' + componentData.id + '/attributes',
								method: 'POST',
								jsonData: attributeData,
								success: function (response, opts) {
									
									// Add Attribute & Code To Component
									componentData.attributes.push({
										
										name: name,
										value: value
									});
									
									// Update Data Display
									assignedComponentGrid.getView().refresh();
									
									// Indicate Successful Removal
									Ext.toast("Attribute Added To " + componentData.name, '', 'tr');
								},
								failure: function (response, opts) {

									// Provide An Error Message
									Ext.toast("Error Adding Attribute To " + componentData.name, '', 'tr');

									// Log Error
									console.log("Error Adding Attribute. See Response:");
									console.log(response);

									// Return Component To Previous Grid
									store_components_local.addSorted(component);
									
									// Select Component
									unassignedComponentGrid.getSelectionModel().select(component);
									
									// Send Focus Temporarily Elsewhere
									assignedComponentGrid.focus();
									
									// Focus On Component
									unassignedComponentGrid.getView().focusRow(component);
									
									// Remove Component From New Grid
									store_assignedComponents_local.remove(component);
								}
							});
						}
					}
				},
				columns: [
					{ 
						text: 'Entries',
						dataIndex: 'name',
						flex: 1,
						renderer: function (value, metaData, record) {

							// Store Record Type
							var recordType = record.get('type');

							// Check If Record Type Is Empty
							if (!recordType) {

								// Build Component Without Record Type
								var html = '<div style="color: #999; margin: 1em 0; padding: 0 0 0.75em 0;">';
								html += '<span style="font-weight: bold;">' + value + "</span>";
								html += "</div>";
							}
							else {

								// Build Component With Record Type
								var html = '<span style="font-weight: bold;">' + value + "</span>";
								html += '<div style="color: #999; margin: 1em 0; padding: 0 0 0.75em 0;">';
								html += '<i class="fa fa-book icon-small-vertical-correction-book fa-fw" style="float:left; margin-right: 2px;"></i> ';
								html += '<span style="float: left;">' + recordType.name + '</span>';
								html += "</div>";
							}
							
							html += '<div>';
							html += '	<button class="attribute-button-inactive" onclick="javascript:displayAttributeList(this, \'attributes_' + record.get('id') + '\')">Existing Attributes <span></span></button>';
							html += '	<ul id="attributes_' + record.get('id') + '" class="attributes-hidden">';
							
							for (var i = 0; i < record.get('attributes').length; i++) {
								
								html += '		<li>';
								html += '			<span class="emboldened">' + record.get('attributes')[i].name + ': </span>';
								html += '			' + record.get('attributes')[i].value;
								html += '		</li>';
							}
							
							html += '	</ul>';
							html += '</div>';
							
							return html;
						}
					}
				]
			});
			
			
			var manageAssignmentsWin = Ext.create('Ext.window.Window', {
				id: 'manageAssignmentsWin',
				title: 'Manage Assignments',
				iconCls: 'fa fa-lg fa-list-alt icon-small-vertical-correction',
				modal: true,
				width: '60%',
				height: '80%',
				maximizable: true,
				y: '2em',
				layout: {
					
					type: 'vbox',
					align: 'stretch'
				},
				items: [
					{
						xtype: 'panel',
						id: 'manageAssignmentsForm-attribute-container',
						flex: 1,
						margin: '10 10 10 10 ',
						layout: 'hbox',
						items: [
							{
								xtype: 'combobox',
								id: 'manageAssignmentsForm-attribute',
								flex: 1,
								fieldLabel: 'Attribute',
								emptyText: '-- Select An Attribute --',
								name: 'attribute',
								store: attributeStore,
								displayField: 'description',
								valueField: 'attributeType',
								listeners: {

									select: function (field, record, opt) {

										// Build URL For Retrieving Attribute Codes
										var url = 'api/v1/resource/attributes/attributetypes';
										url += '/' + record.get('attributeType') + '/attributecodeviews?all=true';

										// Configure Code Store With New URL
										codesStore.setProxy({

											type: 'ajax',
											url: url,
											reader: {

												type: 'json',
												rootProperty: 'data'
											}
										});

										// Filter Code Store Based On Active Status
										// (Only Show Active Records)
										codesStore.filter('activeStatus', 'A');

										// Load Data In Store
										codesStore.load();

										// Enable Code Selection Combo Box
										Ext.getCmp('manageAssignmentsForm-code').enable();
									},

									change: function (field, newValue, oldValue, opts) {

										// Get Current Selection
										var selection = field.getSelection();

										// Check If We Previously Had A Selection
										if (selection != null && selection.get('attributeType') != newValue) {

											// Reset Field (Remove Selection)
											field.reset();

											// Put New Value Back Into Field
											field.setValue(newValue);

											// Reset Attribute Code Selection Field
											Ext.getCmp('manageAssignmentsForm-code').reset();

											// Disable Attribute Code Selection Field
											// (Will Re-Enable When Another Selection Is Made)
											Ext.getCmp('manageAssignmentsForm-code').disable();
										}
									}
								}
							}
						]
					},
					{
						xtype: 'panel',
						id: 'manageAssignmentsForm-code-container',
						flex: 1,
						margin: '10 10 10 10',
						layout: 'hbox',
						items: [
							{
								xtype: 'combobox',
								id: 'manageAssignmentsForm-code',
								flex: 1,
								fieldLabel: 'Attribute Code',
								emptyText: '-- Select An Attribute Code --',
								name: 'attributeCode',
								disabled: true,
								forceSelection: true,
								editable: false,
								store: codesStore,
								displayField: 'label',
								valueField: 'code',
								listeners: {

									select: function (field, newValue, oldValue, opt) {

										// Enable Component Grids
										Ext.getCmp('unassignedComponentGrid').enable();
										Ext.getCmp('assignedComponentGrid').enable();
										
										// Refresh Entry Grid Panels
										refreshEntryGridPanels();
									}
								}
							}
						]
					},
					{
						xtype: 'panel',
						id: 'manageAssignmentsForm-entries-container',
						flex: 18,
						layout: {
							type: 'hbox',
							align: 'stretch'
						},
						items: [
							{
								title: 'Unassigned Entries',
								xtype: 'panel',
								margin: '5 5 5 5',
								flex: 2,
								id: 'manageAssignmentsForm-entries-unassigned-container',
								layout: {
									type: 'hbox',
									align: 'stretch'
								},
								items: [

									unassignedComponentGrid
								]
							},
							{
								title: 'Assigned Entries',
								xtype: 'panel',
								margin: '5 5 5 5',
								flex: 2,
								id: 'manageAssignmentsForm-entries-assigned-container',
								layout: {
									type: 'hbox',
									align: 'stretch'
								},
								items: [

									assignedComponentGrid
								]
							}
						]
					}
				],
				dockedItems: [
					{
						xtype: 'toolbar',
						dock: 'bottom',
						items: [
							{
								xtype: 'tbfill',
							},
							{
								text: 'Close',
								iconCls: 'fa fa-lg fa-close icon-button-color-warning',
								handler: function () {
									
									// Hide Attribute Management Window
									Ext.getCmp('manageAssignmentsWin').hide();
								}
							}
						]
					}
				],
				listeners: {
					
					hide: function() {
						
						// Reset Attribute Code Selection Field
						Ext.getCmp('manageAssignmentsForm-code').reset();

						// Disable Attribute Code Selection Field
						Ext.getCmp('manageAssignmentsForm-code').disable();

						// Disable Assigned Components Grid
						Ext.getCmp('assignedComponentGrid').disable();

						// Disable Unassigned Components Grid
						Ext.getCmp('unassignedComponentGrid').disable();

						// Reset Attribute Selection Field
						Ext.getCmp('manageAssignmentsForm-attribute').reset();

						// Clear Out Component Stores
						store_components_remote.removeAll();
						store_components_local.removeAll();
						store_assignedComponents_local.removeAll();
					}
				}
			});
			
			
			addComponentToMainViewPort(attributeGrid);
			

		});		
		</script>
		</stripes:layout-component>
		</stripes:layout-render>
