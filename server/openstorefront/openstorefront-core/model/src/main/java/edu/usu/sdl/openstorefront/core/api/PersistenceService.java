/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package edu.usu.sdl.openstorefront.core.api;

import edu.usu.sdl.openstorefront.core.api.query.QueryByExample;
import edu.usu.sdl.openstorefront.core.entity.BaseEntity;
import edu.usu.sdl.openstorefront.core.entity.StandardEntity;
import java.util.List;
import java.util.Map;

/**
 *
 * @author dshurtleff
 */
public interface PersistenceService
{

	void begin();

	void commit();

	long countByExample(BaseEntity example);

	long countByExample(QueryByExample queryByExample);

	long countClass(Class entityClass);

	/**
	 * Detaches the whole object tree and removes the proxy object
	 *
	 * @param <T>
	 * @param entity object to detach
	 * @return detached version of the object
	 */
	<T> T deattachAll(T entity);

	<T> void delete(T entity);

	<T> int deleteByExample(BaseEntity example);

	<T> int deleteByExample(QueryByExample queryByExample);

	int deleteByQuery(Class entityClass, String whereClause, Map<String, Object> queryParams);

	/**
	 * Detaches and removes the proxy object
	 *
	 * @param <T>
	 * @param entity object to detach
	 * @return detached version of the object
	 */
	<T> T detach(T entity);

	void endTransaction();

	/**
	 * This only works on managed objects
	 *
	 * @param <T>
	 * @param entityClass
	 * @param primaryKey (DB RID not our Entity PK)
	 * @return
	 */
	@SuppressWarnings(value = "unchecked")
	<T> T find(Class<T> entityClass, Object primaryKey);

	<T> T findById(Class<T> entity, Object id);

	String generateId();

	boolean isManaged(BaseEntity baseEntity);

	boolean isProxy(BaseEntity baseEntity);

	boolean isTransactionActive();

	<T extends BaseEntity> T persist(T entity);

	/**
	 * This will run the query and returns the Proxy Objects
	 *
	 * @param <T> Type of results expected
	 * @param query SQL query for selecting items
	 * <div style="font-size:.9 em">(e.g. SELECT FROM Component WHERE
	 * activeStatus &lt;&gt; :selectedStatus)</div>
	 * @param parameterMap Values to use in the Query
	 * <div style="font-size:.9 em; left: 10px">map with key "selectedStatus"
	 * and value 'A' </div>
	 * @return List of results of the given type
	 */
	<T> List<T> query(String query, Map<String, Object> parameterMap);

	/**
	 * This will run the query and then unwrap if desired
	 *
	 * @param <T> Type of results expected
	 * @param query SQL query for selecting items
	 * <div style="font-size:.9 em">(e.g. SELECT FROM Component WHERE
	 * activeStatus &lt;&gt; :selectedStatus)</div>
	 * @param parameterMap Values to use in the Query
	 * <div style="font-size:.9 em; left: 10px">map with key "selectedStatus"
	 * and value 'A' </div>
	 * @param unwrap detach objects from the database backed objects
	 * @return List of results of the given type
	 */
	<T> List<T> query(String query, Map<String, Object> parameterMap, boolean unwrap);

	/**
	 * This will run the example with the default options
	 *
	 * @param <T> type of object to return
	 * @param baseEntity class containing the criteria for the query
	 * @return List of results of the given type
	 */
	<T> List<T> queryByExample(BaseEntity baseEntity);

	/**
	 *
	 * @param <T> type of object to return
	 * @param queryByExample Query object with the criteria for the query
	 * @return List of results of the given type
	 */
	<T> List<T> queryByExample(QueryByExample queryByExample);

	/**
	 * This just returns one result. Typically the query results in only one
	 * entity.
	 *
	 * @param <T> type of object to return
	 * @param baseEntity class containing the criteria for the query
	 * @return the entity or null if not found
	 */
	<T> T queryOneByExample(BaseEntity baseEntity);

	/**
	 *
	 * @param <T> type of object to return
	 * @param queryByExample Query object with the criteria for the query
	 * @return the entity or null if not found
	 */
	<T> T queryOneByExample(QueryByExample queryByExample);

	void rollback();

	<T> int runDbCommand(String query, Map<String, Object> queryParams);

	/**
	 * This is used for non-base entity object. Keep in mind they still need to
	 * be registered with the DB.
	 *
	 * @param <T>
	 * @param entity
	 * @return
	 */
	<T> T saveNonBaseEntity(T entity);

	<T extends BaseEntity> T saveNonPkEntity(T entity);

	<T extends StandardEntity> T setStatusOnEntity(Class<T> entity, Object id, String activeStatus);

	/**
	 * Detach a list of objects from the database backed objects
	 *
	 * @param <T> type of object
	 * @param data data that needs detached
	 * @return list of detached objects
	 */
	<T> List<T> unwrapProxy(List<T> data);

	/**
	 * Detach a single object from the database backed object
	 *
	 * @param <T> type of object
	 * @param data data that needs detached
	 * @return a detached version of the object
	 */
	<T> T unwrapProxyObject(T data);

	<T> int updateByExample(Class<T> entityClass, T exampleSet, T exampleWhere);

}
