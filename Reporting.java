package Temp1_Phase3.Phase3.src;

import java.util.Scanner;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Statement;

public class Reporting {

	static Connection conn;

	public Reporting() {
		try {
			conn = ConnectionFactory.getConnection();
		} catch (Exception e) {
			conn = null;
		}
	}

	public static void main(String[] args) {
		// TODO Auto-generated method stub

		System.out.print("java Reporting");
		Scanner reader = new Scanner(System.in);
		String user = reader.nextLine();
		String pass = reader.nextLine();
		Integer val = reader.nextInt();
		checkDatabase(val);
		reader.close();

	}

	public static void checkDatabase(Integer value) {
		if (value == null || value == 0) {
			reportEverything();
		} else if (value == 1) {
			reportPatient();
		} else if (value == 2) {
			reportDoctor();
		} else if (value == 3) {
			reportAdmission();
		} else if (value == 4) {
			updateAdmission();
		} else {
			System.out.println("Number does not exist.");
			// reader.close();
		}
	}

	public static void reportEverything() {
		System.out.println("1- Report Patients Basic Information");
		System.out.println("2- Report Doctors Basic Information");
		System.out.println("3- Report Admissions Information");
		System.out.println("4- Update Admissions Payment");

	}

	public static void reportPatient() {
		Scanner reader = new Scanner(System.in);
		System.out.print("Enter Patient SSN: ");
		String input = reader.nextLine();
		reader.close();
		System.out.println(input);
		try {
			PreparedStatement pstmt = conn.prepareStatement("Select * FROM Patient WHERE SSN=?;");
			pstmt.setString(1, input);
			ResultSet rs = pstmt.executeQuery();
			while (rs.next()) {
				System.out.println("Patient SSN: " + rs.getString("SSN"));
				System.out.println("Patient First Name: " + rs.getString("fName"));
				System.out.println("Patient Last Name: " + rs.getString("lName"));
				System.out.println("Patient Address: " + rs.getString("address"));
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void reportDoctor() {
		Scanner reader = new Scanner(System.in);
		System.out.print("Enter Doctor ID: ");
		String input = reader.nextLine();
		reader.close();
		try {
			PreparedStatement pstmt = conn.prepareStatement("Select * FROM Doctor WHERE ID=?;");
			pstmt.setString(1, input);
			ResultSet rs = pstmt.executeQuery();
			while (rs.next()) {
				System.out.println("Doctor ID: " + rs.getString("ID"));
				System.out.println("Doctor First Name: " + rs.getString("fName"));
				System.out.println("Doctor Last Name: " + rs.getString("lName"));
				System.out.println("Doctor Gender: " + rs.getString("gender"));
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void reportAdmission() {
		Scanner reader = new Scanner(System.in);
		System.out.print("Enter Admission Number: ");
		String input = reader.nextLine();
		reader.close();
		try {
			PreparedStatement pstmt = conn.prepareStatement("Select * FROM Admission WHERE num=?;");
			pstmt.setString(1, input);
			ResultSet rs = pstmt.executeQuery();
			while (rs.next()) {
				System.out.println("Admission Number: " + rs.getString("num"));
				System.out.println("Patient SSN: " + rs.getString("patientSSN"));
				System.out.println("Admission Date " + rs.getString("admissionDate"));
				System.out.println("TotalPayment: " + rs.getString("totalPayment"));
				try {
					PreparedStatement pstmt2 = conn.prepareStatement("Select * FROM StayIn WHERE admissionNum=?;");
					pstmt.setString(1, input);
					ResultSet rs2 = pstmt.executeQuery();
					while (rs2.next()) {
						System.out.println("RoomNum: " + rs2.getString("roomNum") + "FromDate: "
								+ rs2.getString("startDate") + "ToDate: " + rs2.getString("endDate"));
					}
				} catch (SQLException f) {

				}
				try {
					PreparedStatement pstmt3 = conn.prepareStatement("Select * FROM Examine WHERE admissionNum=?;");
					pstmt.setString(1, input);
					ResultSet rs3 = pstmt.executeQuery();
					while (rs3.next()) {
						System.out.println("Doctor ID: " + rs3.getString("doctorID"));
					}
				} catch (SQLException g) {

				}
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void updateAdmission() {
		Scanner reader = new Scanner(System.in);
		System.out.print("Enter Admission Number: ");
		String input = reader.nextLine();
		System.out.print("Enter the new total payment: ");
		String input2 = reader.nextLine();
		reader.close();
		try {
			PreparedStatement pstmt = conn.prepareStatement("UPDATE Admission SET totalPayment=? WHERE num=?;");
			pstmt.setString(1, input2);
			pstmt.setString(2, input);
			ResultSet rs = pstmt.executeQuery();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
