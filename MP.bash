#!/bin/bash
exec 2>>errors.txt #remove this line to show warnings/errors not covered by checkers

#-----FUNCTIONS
initdb()
{
echo -n "Enter MYSQL password for $WHO: "
read -s PASSWORD
echo "$PASSWORD"

mysql MP -u $WHO -p"$PASSWORD" -e "DESCRIBE StudRec;" >>/dev/null
	if [[ $? != 0 ]]; then
		echo -n "Initializing your database(first time use)"
		sleep 1
		echo -n "."
		sleep 1
		echo -n "."
		mysql $WHO -p"$PASSWORD" -e "CREATE DATABASE IF NOT EXISTS MP;"
		mysql $WHO -p"$PASSWORD" MP -e "CREATE TABLE StudRec (Student_No INT PRIMARY KEY, Last_Name VARCHAR(20), First_Name VARCHAR(20), Program VARCHAR(30), Email VARCHAR(40) UNIQUE, Gender VARCHAR(6), Birthdate VARCHAR(10), Contact_No VARCHAR(11) UNIQUE);"
		echo "New database initialized!"
		EVENT="DBA_INIT"
		LOGS $EVENT
	else
		echo "Database initialized already initialized."
	fi
}

numcheck() #checks for null/number/special character inputs
{
	ENTRY=""
###NULL
	if [ -z $1 ]; then
		echo "No input detected. Please try again." 
		EVENT="NULL_INP"
		LOGS $EVENT
###NUMBERS
	elif [[ $1 =~ [0-9] ]]; then
		echo "Contains numbers. Please try again." 
		EVENT="NUM_INP"
		LOGS $EVENT
###SPECIAL
	elif [[ ! $1 =~ ^[[:alnum:]]+$ ]]; then
		echo "Contains special characters. Please try again."
		EVENT="SPEC_INP"
		LOGS $EVENT
	else
		ENTRY="CORRECT"
	fi
}

alphacheck() #checks for null/character/special character inputs
{
	ENTRY=""
###NULL
	if [ -z $1 ]; then
		echo "No input detected. Please try again."
		EVENT="NULL_INP"
		LOGS $EVENT
###CHARACTERS
	elif [[ $1 =~ [A-Za-z] ]]; then
		echo "Contains letters. Please try again."
		EVENT="LETTER_INP"
		LOGS $EVENT
	elif [[ ! $1 =~ ^[[:alnum:]]+$ ]]; then
		echo "Contains special characters. Please try again."
		EVENT="SPEC_INP"
		LOGS $EVENT
	else
		ENTRY="CORRECT"
	fi
}

dobcheck() #check for correct date of birth entry
{
	ENTRY=""
MM=${1:0:2}
DD=${1:3:2}
YYYY=${1:6:4}

	if [[ ${#1} -ne 10 ]]; then
		echo "Incorrect length input. Please try again."
		EVENT="INLEN_INP"
		LOGS $EVENT
	elif [[ $MM -gt 12 ]]; then
		echo "Exceeded Month."
		EVENT="MONT_INP"
		LOGS $EVENT
	else
		ENTRY="CORRECT"
	fi

date -d $1 >/dev/null

	if [[ ! $? = 0 ]]; then
		echo "Invalid date. Please check month and day. Try again."
		EVENT="INV_DATE"
		LOGS $EVENT
	fi
}

ADDREC() #Add Record
{
ENTRY=""
until [[ $ENTRY = "CORRECT" ]]; do #UNARY OPERATOR FIX
echo -n "Enter Last Name: "
read LN
numcheck $LN
done
ENTRY=""

until [ $ENTRY = "CORRECT" ]; do
echo -n "Enter First Name: "
read FN
numcheck $FN
done
ENTRY=""

until [ $ENTRY = "CORRECT" ]; do
echo -n "Enter Student Number: "
read SN

	if [[ ${#SN} -ne 10 ]]; then
		echo "Incorrect length input."
		EVENT="LEN_INP"
		LOGS $EVENT
		ENTRY=""
	else
		alphacheck $SN
	fi
		duplicheck $SN
done
ENTRY=""

until [ $ENTRY = "CORRECT" ]; do
echo -n "Enter Program: "
read PR
numcheck $PR
done
ENTRY=""

until [ $ENTRY = "CORRECT" ]; do
echo -n "Enter Email: "
read EM
duplicheck $EM 
done
ENTRY=""

echo -n "Enter Gender: "
read GD

until [ $ENTRY = "CORRECT" ]; do
echo -n "Enter Birthday: "
read BD
dobcheck $BD
done
ENTRY=""

until [ $ENTRY = "CORRECT" ]; do
echo -n "Enter CP Number: "
read CP

	if [[ ${#CP} -ne 11 ]]; then
		echo "Incorrect length input."
		EVENT="LEN_INP"
		LOGS $EVENT
		ENTRY=""
	else
		alphacheck $CP
	fi
duplicheck $CP
done
ENTRY=""	

mysql MP -u $WHO -p"$PASSWORD" -e "INSERT INTO StudRec (Student_No,Last_Name,First_Name,Program,Email,Gender,Birthdate,Contact_No) VALUES ('$SN','$LN','$FN','$PR','$EM','$GD','$BD','$CP');" 
echo "Added record."
echo " "
EVENT="REC_ADDED"
LOGS $EVENT
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * FROM StudRec;"
AGAIN_OPT="ADDREC"
AGAIN_TXT="Add Record"
AGAIN
}

DELREC() #Delete Record
{
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * FROM StudRec;"
echo -n "Enter Student number of a record you want to delete: "
read DEL
alphacheck $DEL
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * FROM StudRec;" | grep -e "$DEL" >> /dev/null

	if [[ $? -eq 0 ]]; then
		mysql MP -u $WHO -p"$PASSWORD" -e "DELETE from StudRec where Student_No='$DEL';"
		echo "Deleted entry."
		echo " "
		EVENT="REC_DELETED"
		LOGS $EVENT
		mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * FROM StudRec;"
	else
		echo "Entry does not exist. Please try again."
		DELREC
	fi
AGAIN_TXT="Delete Record"
AGAIN_OPT="DELREC"
}

EDITREC() #Edit Record
{
echo -n "Enter Student Number of a record you want to edit: "
read EDIT
alphacheck $EDIT
keycheck $EDIT
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec WHERE Student_No LIKE "$EDIT";"
CTR=0
while [ $CTR -eq 0 ]; do
	(( CTR = CTR + 1 ))
echo "Student Number(1), Last Name(2), First Name(3), Program(4), Email(5), Gender(6), Birthdate(7), Contact Number(8), Cancel(C/c): "
echo -n "Enter the number of what field you want to edit: "
read FLD
ENTRY=""
	case $FLD in
		1)
			until [ $ENTRY = "CORRECT" ]; do
			CLMN="Student_No"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			alphacheck $UPDT
			done
			ENTRY=""
			;;
		2)
			until [ $ENTRY = "CORRECT" ]; do
			CLMN="Last_Name"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			numcheck $UPDT
			done
			ENTRY=""
			;;
		3)
			until [ $ENTRY = "CORRECT" ]; do
			CLMN="First_Name"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			numcheck $UPDT
			done
			ENTRY=""
			;;
		4)
			#until [ $ENTRY = "CORRECT" ]; do
			CLMN="Program"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			numcheck $UPDT
		#	done
			ENTRY=""
			;;
		5)
			CLMN="Email"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			;;
		6)
			until [ $ENTRY = "CORRECT" ]; do
			CLMN="Gender"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			numcheck $UPDT
			done
			ENTRY=""
			;;
		7)
			until [ $ENTRY = "CORRECT" ]; do
			CLMN="Birthdate"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			dobcheck $UPDT
			done
			ENTRY=""
			;;
		8)
			until [ $ENTRY = "CORRECT" ]; do
			CLMN="Contact_No"
			echo -n "Enter updated information for $CLMN : "
			read UPDT
			alphacheck $UPDT
			done
			ENTRY=""
			;;
		[cC])
			AGAIN_TXT="Edit Record"
			AGAIN_OPT="EDITREC"
			AGAIN
			;;
		*)
			echo "Wrong option, please try again."
			CTR=0
		esac
#done
mysql MP -u $WHO -p"$PASSWORD" -e "UPDATE StudRec SET $CLMN = '$UPDT' WHERE Student_No='$EDIT';"
done
echo "CHANGES MADE."
echo " "
EVENT="REC_EDITED"
LOGS $EVENT
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * FROM StudRec WHERE Student_No LIKE "$EDIT";"
AGAIN_TXT="Edit Record"
AGAIN_OPT="EDITREC"
}

VIEWREC() #View Record
{
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec;"
	while true; do
		echo -n "Do you want to search the records? (Y/y or N/n): "
		read OPT
		if [[ $OPT = "Y" || $OPT = "y" ]]; then
			EVENT="REC_SEARCH"
			LOGS $EVENT
			echo "Student Number(1), Last Name(2), First Name(3), Email(4), Contact Number(5), Cancel(C/c): "
			echo -n "Enter the number what field you want to search: "
			read FLD

	case $FLD in
		1)
			echo -n "Search Student Number: "
			read STUDNO
			alphacheck $STUDNO
			clear
			mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec WHERE Student_No LIKE "$STUDNO";"
			;;
		2)	
			echo -n "Search Last Name: "
			read LASTN
			numcheck $LASTN
			clear
			mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * FROM StudRec WHERE Last_Name = '$LASTN';"
			;;
		3)
			echo -n "Search First Name: "
			read FIRSTN
			numcheck $FIRSTN
			clear
			mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec WHERE First_Name LIKE '$FIRST';"
			
			;;
		4)
			echo -n "Search Email: "
			read EMAIL
			clear
			mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec WHERE Email LIKE '$EMAIL';"
			;;
		5)
			echo -n "Search Contact Number: "
			read CONTACT
			alphacheck $CONTACT
			clear
			mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec WHERE Contact_No LIKE '$CONTACT';"
			;;
		[cC])
			AGAIN
			echo -n "Do you want to sort the records?"
				
			;;
		*)
			echo "Wrong option, please try again."
			;;
		esac

	elif [[ $OPT = "N" || $OPT = "n" ]]; then
		while true; do
			echo -n "Do you want to sort the records? (Y/y or N/n): "
			read OPT
			if [[ $OPT = "Y" || $OPT = "y" ]]; then
				sorter
			elif [[ $OPT = "N" || $OPT = "n" ]];then
				AGAIN_OPT="VIEWREC"
				AGAIN_TXT="View Records"
				AGAIN
			fi
		done
	else
		echo "Invalid Choice"
		EVENT="INV_CHOICE"
		LOGS $EVENT
	fi
done
AGAIN_OPT="VIEWREC"
AGAIN_TXT"View Records"
}

sorter() #Sort Records
{
echo "Student Number(1), Last Name(2), First Name(3), Email(4), Contact Number(5) Gender(6),Program(7), Cancel(C/c): "
echo -n "Enter the number what field you want to sort: "
read FLD

	case $FLD in
		1)
			echo -n "Ascending or Descending? (A/D): "
			read ORDER
			numcheck $ORDER
			clear
			if [[ $ORDER = "A" || $ORDER = "a" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Student_No ASC;"
			elif [[ $ORDER = "D" || $ORDER = "d" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Student_No DESC;"
			else
				echo "Wrong input, please try again."
				sorter
			fi
			;;
		2)
			echo -n "Ascending or Descending? (A/D): "
			read ORDER
			numcheck $ORDER
			clear
			if [[ $ORDER = "A" || $ORDER = "a" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Last_Name ASC;"
			elif [[ $ORDER = "D" || $ORDER = "d" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Last_Name DESC;"
			else
				echo "Wrong input, please try again."
				sorter
			fi
			;;
		3)
			echo -n "Ascending or Descending? (A/D): "
			read ORDER
			numcheck $ORDER
			clear
			if [[ $ORDER = "A" || $ORDER = "a" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY First_Name ASC;"
			elif [[ $ORDER = "D" || $ORDER = "d" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY First_Name DESC;"
			else
				echo "Wrong input, please try again."
				sorter
			fi
			;;
		4)
			echo -n "Ascending or Descending? (A/D): "
			read ORDER
			numcheck $ORDER
			clear
			if [[ $ORDER = "A" || $ORDER = "a" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Email ASC;"
			elif [[ $ORDER = "D" || $ORDER = "d" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Email DESC;"
			else
				echo "Wrong input, please try again."
				sorter
			fi
			;;
		5)
			echo -n "Ascending or Descending? (A/D): "
			read ORDER
			numcheck $ORDER
			clear
			if [[ $ORDER = "A" || $ORDER = "a" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Contact_No ASC;"
			elif [[ $ORDER = "D" || $ORDER = "d" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Contact_No DESC;"
			else
				echo "Wrong input, please try again."
				sorter
			fi
			;;
		6)
			echo -n "Ascending or Descending? (A/D): "
			read ORDER
			numcheck $ORDER
			clear
			if [[ $ORDER = "A" || $ORDER = "a" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Gender ASC;"
			elif [[ $ORDER = "D" || $ORDER = "d" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Gender DESC;"
			else
				echo "Wrong input, please try again."
				sorter
			fi
			;;
		7)
			echo -n "Ascending or Descending? (A/D): "
			read ORDER
			numcheck $ORDER
			clear
			if [[ $ORDER = "A" || $ORDER = "a" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Program ASC;"
			elif [[ $ORDER = "D" || $ORDER = "d" ]]; then
				mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec ORDER BY Program DESC;"
			else
				echo "Wrong input, please try again."
				sorter
			fi
			;;
		[cC])
			AGAIN
			;;
		*)
			echo "Wrong option, please try again."
		esac
EVENT="REC_SORT"
LOGS $EVENT
}

keycheck() #Checks for the primary key(Student_No)
{
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT Student_No from StudRec WHERE Student_No LIKE "$1";" | grep -e "$1" >> /dev/null
	if [[ $? != 0 ]]; then
		echo "There is no $1 on the record, please try again."
		EVENT="NOKEY_REC"
		LOGS $EVENT
		EDITREC
	fi
}

duplicheck() #checks for any duplicate in the records
{
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * from StudRec;" | grep -e "$1" >> /dev/null 
	if [[ $? = 0 ]]; then
		echo "There is already an existing $1 on the record, please try again."
		EVENT="EXIST_INP"
		LOGS $EVENT
		ENTRY=""
	else
		ENTRY="CORRECT"
	fi
}

LOADREC() #append to existing records
{
echo -n "Please Enter File location: "
read LOC

	if [ -d "$LOC" ]; then
		ls $LOC
		echo -n "Enter Name of SQL file to be appended: "
		read SQFILE
			if [ -f $SQFILE ]; then
				mysql -u $WHO -p"$PASSWORD" -e "CREATE DATABASE temp;"
				mysql -u $WHO -p"$PASSWORD" temp < "$LOC/$SQFILE"
				mysql -u $WHO -p"$PASSWORD" -e "INSERT IGNORE INTO MP.StudRec SELECT * FROM temp.StudRec;"
				mysql -u $WHO -p"$PASSWORD" -e "DROP DATABASE temp;"
			else
				echo "File does not exist, try again"
				EVENT="DNE_FILE"
				LOGS $EVENT
				LOADREC
			fi
	else
		echo "Does not exist, try again."
		EVENT="DNE_DIRLOC"
		LOGS $EVENT
		LOADREC
	fi

echo "Successfully appended records."
EVENT="REC_APPENDED"
LOGS $EVENT
mysql MP -u $WHO -p"$PASSWORD" -e "SELECT * FROM StudRec;"
AGAIN_OPT="LOADREC"
AGAIN_TXT="Load Records"
}

MAIN() #Main Menu
{
clear
echo -e "\t \t \t \t Student Record System using MySQL Database"
echo "[1] Add Record"
echo "[2] Edit Record"
echo "[3] Delete Record"
echo "[4] View Record with Sort"
echo "[5] Load Record"
echo "[6] View Logs"
echo "[7] Read Manual"
echo "[0] Exit Program"

echo -n "Enter option: "
read OPT

	case $OPT in
		1)
			EVENT="ADD_RECORD"
			LOGS $EVENT
			ADDREC
			AGAIN
			;;
		2)
			EVENT="EDIT_RECORD"
			LOGS $EVENT
			EDITREC
			AGAIN
			;;
		3)
			EVENT="DELETE_RECORD"
			LOGS $EVENT
			DELREC
			AGAIN
			;;
		4)
			EVENT="VIEW_RECORD"
			LOGS $EVENT
			VIEWREC
			AGAIN
			;;
		5)
			EVENT="LOAD_RECORD"
			LOADREC
			AGAIN
			;;
		6)
			EVENT="VIEW_LOGS"
			LOGS $EVENT
			cat logs.txt | less
			MAIN
			;;
		7)
			EVENT="READ_MANUAL"
			cat manual.txt | less
			MAIN
			;;

		0)
			EVENT="EXIT_PROGRAM"
			LOGS $EVENT
			echo "You have exited the program."
			exit 0
			;;
		*)
			echo "INVALID INPUT!"
			EVENT="INV_CHOICE"
			LOGS $EVENT
			echo -n "Try again in 3."
			sleep 1
			echo -n "2."
			sleep 1
			echo -n "1.."
			sleep 1
			MAIN
		;;
	esac
}

AGAIN() #Try again prompt
{
echo -n "Do you wish to $AGAIN_TXT again?(Y/y or N/n to return to Main Menu): "
read OPT

	if [[ $OPT = "Y" || $OPT = "y" ]]; then
		$AGAIN_OPT
	elif [[ $OPT = "N" || $OPT = "n" ]]; then
		MAIN
	else 
		echo "Invalid Choice."
		EVENT="INV_CHOICE"
		LOGS $EVENT
		AGAIN
	fi
}

LOGS() #Initalize and save logs
{
cat logs.txt | grep -e $DBNAME >>/dev/null
	if [[ $? != 0 ]]; then
		echo  "USER	DATE	TIME		EVENT	DBNAME" >> logs.txt
		echo  "$WHO	$DATE	$TIME		$1	$DBNAME" >> logs.txt
	else
		echo  "$WHO	$DATE	$TIME		$1	$DBNAME" >> logs.txt

	fi
}
#-----FUNCTIONS

###---MAIN PROGRAM
DATE=$(date +%D)
TIME=$(date +%r)
WHO=$(whoami)
DBNAME="StudRec"
EVENT="OPEN_PROGRAM"
ENTRY=""
LOGS $EVENT
initdb
MAIN
exec 2>>errors.txt #remove this line to show warnings/errors not covered by checkers
exit 0
###---MAIN PROGRAM
