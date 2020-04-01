package Temp1_Phase3.Phase3.src;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;


//Connection to Database

public class ConnectionFactory {

	static Connection conn;
	
	public static Connection getConnection() throws Exception {
		if(conn != null) {
			return conn;
		}
		try {
			Class.forName("oracle.jdbc.driver.OracleDriver");
			conn = DriverManager.getConnection(
					"jdbc:oracle:thin:@oracle.wpi.edu:1521:orcl", "jlovering",
					"Ape07Bean99");
			return conn;
		}catch(SQLException e) {
			throw new RuntimeException("Error connecting to the database.", e);
		}
	}
	
	//Test Connection
	
	/*
    public static void main(String[] args) {
        Connection connection = ConnectionFactory.getConnection();
    }
    */
}