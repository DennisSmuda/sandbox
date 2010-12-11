package cassandratutorial;

import static me.prettyprint.hector.api.factory.HFactory.createColumn;
import static me.prettyprint.hector.api.factory.HFactory.createColumnQuery;
import static me.prettyprint.hector.api.factory.HFactory.createKeyspace;
import static me.prettyprint.hector.api.factory.HFactory.createMultigetSliceQuery;
import static me.prettyprint.hector.api.factory.HFactory.createMutator;
import static me.prettyprint.hector.api.factory.HFactory.getOrCreateCluster;

import java.util.HashMap;
import java.util.Map;

import me.prettyprint.cassandra.serializers.StringSerializer;
import me.prettyprint.hector.api.Cluster;
import me.prettyprint.hector.api.Keyspace;
import me.prettyprint.hector.api.beans.HColumn;
import me.prettyprint.hector.api.beans.Rows;
import me.prettyprint.hector.api.exceptions.HectorException;
import me.prettyprint.hector.api.mutation.Mutator;
import me.prettyprint.hector.api.query.ColumnQuery;
import me.prettyprint.hector.api.query.MultigetSliceQuery;
import me.prettyprint.hector.api.query.QueryResult;

public class ExampleDaoV2 {

  private final static String KEYSPACE = "Keyspace1";
  private final static String HOST_PORT = "localhost:9160";
  private final static String CF_NAME = "Standard1";
  /** Column name where values are stored */
  private final static String COLUMN_NAME = "v";
  private final StringSerializer serializer = StringSerializer.get();

  private final Keyspace keyspace;

  public static void main(String[] args) throws HectorException {
    Cluster c = getOrCreateCluster("MyCluster", HOST_PORT);
    ExampleDaoV2 ed = new ExampleDaoV2(createKeyspace(KEYSPACE, c));
    int count = 100;
    for (int i = 0; i < count; i++) {
    	ed.insert("key" + i, "value" + i);	
    }
    for (int i = 0; i < count; i++) {
    	System.out.println(ed.get("key" + i));
    }
    
  }

  public ExampleDaoV2(Keyspace keyspace) {
    this.keyspace = keyspace;
  }

  /**
   * Insert a new value keyed by key
   *
   * @param key   Key for the value
   * @param value the String value to insert
   */
  public void insert(final String key, final String value) {
    Mutator m = createMutator(keyspace);
    m.insert(key, CF_NAME, createColumn(COLUMN_NAME, value, serializer, serializer));
  }

  private long createTimestamp() {
    return keyspace.createTimestamp();
  }

  /**
   * Get a string value.
   *
   * @return The string value; null if no value exists for the given key.
   */
  public String get(final String key) throws HectorException {
    ColumnQuery<String, String> q = createColumnQuery(keyspace, serializer, serializer);
    QueryResult<HColumn<String, String>> r = q.setKey(key).
        setName(COLUMN_NAME).
        setColumnFamily(CF_NAME).
        execute();
    HColumn<String, String> c = r.get();
    return c == null ? null : c.getValue();
  }

  /**
   * Get multiple values
   * @param keys
   * @return
   */
  public Map<String, String> getMulti(String... keys) {
    MultigetSliceQuery<String,String> q = createMultigetSliceQuery(keyspace, serializer, serializer);
    q.setColumnFamily(CF_NAME);
    q.setKeys(keys);
    q.setColumnNames(COLUMN_NAME);

    QueryResult<Rows<String,String>> r = q.execute();
    Rows<String, String> rows = r.get();
    Map<String, String> ret = new HashMap<String, String>(keys.length);
    for (String k: keys) {
      HColumn<String, String> c = rows.getByKey(k).getColumnSlice().getColumnByName(COLUMN_NAME);
      if (c != null && c.getValue() != null) {
        ret.put(k, c.getValue());
      }
    }
    return ret;
  }

  /**
   * Insert multiple values
   */
  public void insertMulti(Map<String, String> keyValues) {
    Mutator m = createMutator(keyspace);
    for (Map.Entry<String, String> keyValue: keyValues.entrySet()) {
      m.addInsertion(keyValue.getKey(), CF_NAME,
          createColumn(COLUMN_NAME, keyValue.getValue(), createTimestamp(), serializer, serializer));
    }
    m.execute();
  }

  /**
   * Delete multiple values
   */
  public void delete(String... keys) {
    Mutator m = createMutator(keyspace);
    for (String key: keys) {
      m.addDeletion(key, CF_NAME,  COLUMN_NAME, serializer);
    }
    m.execute();
  }
}