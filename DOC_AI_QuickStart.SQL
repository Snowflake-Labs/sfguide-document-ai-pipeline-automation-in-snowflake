Create or replace database DS_DEV_DB;

create or replace schema DOC_AI_SCHEMA;

create or replace warehouse DS_DEV_WH;

CREATE STAGE INVOICE_DOCS 
	DIRECTORY = ( ENABLE = true ) 
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

CREATE STAGE IGNOIRED_DOCS 
	DIRECTORY = ( ENABLE = true ) 
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

CREATE STAGE MANUAL_REVIEW 
	DIRECTORY = ( ENABLE = true ) 
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );


CREATE OR REPLACE STREAM DS_DEV_DB.DOC_AI_SCHEMA.PREPROCESS_STREAM 
ON DIRECTORY(@INVOICE_DOCS);
  

CREATE OR REPLACE TABLE DS_DEV_DB.DOC_AI_SCHEMA.MODEL_METADATA (
    MODEL_NAME VARCHAR(255),          
    FLATTEN_TABLE VARCHAR(255),       
    VALIDATED_TABLE VARCHAR(255), 
    FAILED_SCORE_TABLE VARCHAR(255),
    FOLDER_NAME VARCHAR(255),         
    PREDICTION_TYPE NUMBER(1)        
);

CREATE OR REPLACE TABLE DS_DEV_DB.DOC_AI_SCHEMA.SCORE_THRESHOLD (
    MODEL_NAME VARCHAR(255),         
    SCORE_NAME VARCHAR(255),         
    SCORE_VALUE FLOAT              
);

create or replace TABLE DS_DEV_DB.DOC_AI_SCHEMA.DOCAI_PREFILTER (
	ROWID NUMBER(38,0) autoincrement start 1 increment 1 noorder,
	MODEL_NAME VARCHAR(255),
	FILENAME VARCHAR(16777216),
	FILESIZE VARCHAR(255),
	NUMBER_OF_PAGES NUMBER(38,0),
	DATECREATED TIMESTAMP_LTZ(9),
	COMMENT VARCHAR(16777216),
	STATUS VARCHAR(16777216),
	PROCESS_START_TIME TIMESTAMP_LTZ(9),
	PROCESS_END_TIME TIMESTAMP_LTZ(9)
);

create or replace TABLE DS_DEV_DB.DOC_AI_SCHEMA.DOCAI_ORDERFORM_EXTRACTION (
	RELATIVEPATH VARCHAR(16777216),
	MODEL_NAME VARCHAR(255),
	SIZE NUMBER(38,0),
	FILE_URL VARCHAR(16777216),
	JSON VARIANT,
	COMMENTS VARCHAR(16777216),
	STATUS VARCHAR(16777216),
	PROCESS_START_TIME TIMESTAMP_LTZ(9),
	PROCESS_END_TIME TIMESTAMP_LTZ(9)
);


CREATE OR REPLACE TABLE DS_DEV_DB.DOC_AI_SCHEMA.invoice_col_score_failed_history (
    SCORE_NAME STRING,         
    SCORE_VALUE FLOAT,         
    DATE_FAILED TIMESTAMP,      
    FILENAME STRING,            
    COMMENTS STRING             
);


CREATE OR REPLACE TABLE DS_DEV_DB.DOC_AI_SCHEMA.purchase_col_score_failed_history (
    SCORE_NAME STRING,         
    SCORE_VALUE FLOAT,          
    DATE_FAILED TIMESTAMP,      
    FILENAME STRING,            
    COMMENTS STRING             
);

CREATE OR REPLACE TABLE DS_DEV_DB.DOC_AI_SCHEMA.manual_review_history_log (
    ID BIGINT AUTOINCREMENT PRIMARY KEY,  
    FILENAME VARCHAR(255) NOT NULL,       
    ACTION VARCHAR(100) NOT NULL,         
    TIMESTAMP TIMESTAMP_NTZ NOT NULL,     
    USER_NAME VARCHAR(100) DEFAULT CURRENT_USER, 
    COMMENTS VARCHAR(500) NULL        
);

CREATE OR REPLACE TABLE Invoice_Flatten (
    RELATIVEPATH STRING,
    MODEL_NAME STRING,
    OCR_SCORE FLOAT,
    DELIVERY_DATE_SCORE FLOAT,
    DELIVERY_DATE_VALUE STRING,
    ORDER_DATE_SCORE FLOAT,
    ORDER_DATE_VALUE STRING,
    PO_NUMBER_SCORE FLOAT,
    PO_NUMBER_VALUE STRING,
    SUB_TOTAL_SCORE FLOAT,
    SUB_TOTAL_VALUE STRING,
    TAX_AMOUNT_SCORE FLOAT,
    TAX_AMOUNT_VALUE STRING,
    TOTAL_AMOUNT_SCORE FLOAT,
    TOTAL_AMOUNT_VALUE STRING,
    COMMENTS STRING,
    STATUS STRING,
    PROCESSED_TIMESTAMP TIMESTAMP,
    PROCESS_START_TIME TIMESTAMP,
    PROCESS_END_TIME TIMESTAMP
);

CREATE OR REPLACE TABLE Purchase_Flatten (
    RELATIVEPATH STRING,                         
    MODEL_NAME STRING,                           
    OCR_SCORE FLOAT,                             
    AMOUNT_SCORE FLOAT,                          
    AMOUNT_VALUE STRING,                         
    DISCOUNT_SCORE FLOAT,                       
    DISCOUNT_VALUE STRING,                       
    INVOICE_DATE_SCORE FLOAT,                   
    INVOICE_DATE_VALUE STRING,                                       
    ITEM_DESCRIPTIONS_SCORE FLOAT,              
    ITEM_DESCRIPTIONS_VALUE STRING,              
    PO_NUMBER_SCORE FLOAT,                       
    PO_NUMBER_VALUE STRING,                      
    QUANTITY_SCORE FLOAT,                        
    QUANTITY_VALUE STRING,                       
    RATE_SCORE FLOAT,                            
    RATE_VALUE STRING,                           
    COMMENTS STRING,                             
    STATUS STRING,                               
    PROCESSED_TIMESTAMP TIMESTAMP,               
    PROCESS_START_TIME TIMESTAMP,                
    PROCESS_END_TIME TIMESTAMP                   
);

CREATE OR REPLACE TABLE Invoice_Validated (
    RELATIVEPATH STRING,
    DELIVERY_DATE_VALUE STRING,
    ORDER_DATE_VALUE STRING,
    PO_NUMBER_VALUE STRING,
    SUB_TOTAL_VALUE STRING,
    TAX_AMOUNT_VALUE STRING,
    TOTAL_AMOUNT_VALUE STRING,
    PROCESS_START_TIME TIMESTAMP,
    PROCESS_END_TIME TIMESTAMP
);

CREATE OR REPLACE TABLE Purchase_Validated (
    RELATIVEPATH STRING,                    
    AMOUNT_VALUE STRING,                    
    DISCOUNT_VALUE STRING,                  
    INVOICE_DATE_VALUE STRING,                              
    ITEM_DESCRIPTIONS_VALUE STRING,          
    PO_NUMBER_VALUE STRING,                  
    QUANTITY_VALUE STRING,                  
    RATE_VALUE STRING,                      
    PROCESS_START_TIME TIMESTAMP,           
    PROCESS_END_TIME TIMESTAMP              
);

INSERT INTO DS_DEV_DB.DOC_AI_SCHEMA.MODEL_METADATA (MODEL_NAME, FLATTEN_TABLE, VALIDATED_TABLE, FAILED_SCORE_TABLE ,FOLDER_NAME, PREDICTION_TYPE)
VALUES
    ('INVOICE_MODEL', 'INVOICE_FLATTEN', 'INVOICE_VALIDATED', 'invoice_col_score_failed_history' ,'Invoice', 2),
    ('PURCHASE_MODEL', 'PURCHASE_FLATTEN', 'PURCHASE_VALIDATED', 'purchase_col_score_failed_history','Purchase', 2);

    
INSERT INTO DS_DEV_DB.DOC_AI_SCHEMA.SCORE_THRESHOLD (MODEL_NAME, SCORE_NAME, SCORE_VALUE)
VALUES
    ('INVOICE_MODEL', 'DELIVERY_DATE', 1),
    ('INVOICE_MODEL', 'ORDER_DATE', 1),
    ('INVOICE_MODEL', 'PO_NUMBER', 1),
    ('INVOICE_MODEL', 'SUB_TOTAL', 1),
    ('INVOICE_MODEL', 'TAX_AMOUNT', 0.998), 
    ('INVOICE_MODEL', 'TOTAL_AMOUNT', 0.998),
    ('INVOICE_MODEL', 'ocrScore', 0.97); 

INSERT INTO DS_DEV_DB.DOC_AI_SCHEMA.SCORE_THRESHOLD (MODEL_NAME, SCORE_NAME, SCORE_VALUE)
VALUES
    ('PURCHASE_MODEL', 'AMOUNT', 1),                      
    ('PURCHASE_MODEL', 'INVOICE_DATE', 1),                       
    ('PURCHASE_MODEL', 'ITEM_DESCRIPTIONS', 1),       
    ('PURCHASE_MODEL', 'PO_NUMBER', 1),             
    ('PURCHASE_MODEL', 'QUANTITY', 1),                
    ('PURCHASE_MODEL', 'RATE', 1),                    
    ('PURCHASE_MODEL', 'ocrScore', 0.97);   


CREATE OR REPLACE PROCEDURE DS_DEV_DB.DOC_AI_SCHEMA.COUNT_PDF_PAGES_PROC()
RETURNS VARCHAR(16777216)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'PyPDF2')
HANDLER = 'count_pages'
EXECUTE AS OWNER
AS '
import snowflake.snowpark as snowpark
import PyPDF2
import os
from datetime import datetime

def count_pages(session):
    # Temporary directory for downloading files
    temp_dir = "/tmp/pdf_files/"
    os.makedirs(temp_dir, exist_ok=True)

    # Stream and table details
    stream_name = "DS_DEV_DB.DOC_AI_SCHEMA.PREPROCESS_STREAM"
    temp_table_name = "STREAMDATA_TEMP"
    prefilter_table_name = "DS_DEV_DB.DOC_AI_SCHEMA.DOCAI_PREFILTER"
    metadata_table_name = "DS_DEV_DB.DOC_AI_SCHEMA.MODEL_METADATA"
    stage_name = "INVOICE_DOCS"

    # Step 1: Create a temporary table to store stream data
    session.sql(f"""
        CREATE OR REPLACE TABLE {temp_table_name} AS
        SELECT * FROM {stream_name} WHERE METADATA$ACTION = ''INSERT'';
    """).collect()

    # Step 2: Fetch data from the temporary table
    temp_data = session.sql(f"SELECT * FROM {temp_table_name}").collect()
    if not temp_data:
        session.sql(f"DROP TABLE IF EXISTS {temp_table_name}").collect()
        return "No files to process in the stream."

    processed_count = 0

    for row in temp_data:
        relative_path = row["RELATIVE_PATH"]  # Extract full relative path (e.g., "Order/2N840077-001.pdf")
        file_size = row["SIZE"]
        stage_file_path = f"@{stage_name}/{relative_path}"
        process_start_time = datetime.now()

        # Step 3: Determine MODEL_NAME dynamically based on folder
        folder_name = relative_path.split("/")[0]  # Get the subfolder name (e.g., "Order" or "Delivery")

        metadata_query = f"""
            SELECT MODEL_NAME 
            FROM {metadata_table_name}
            WHERE FOLDER_NAME = ''{folder_name}''
            LIMIT 1
        """
        metadata_result = session.sql(metadata_query).collect()

        # Fallback to UNKNOWN if no match is found
        if metadata_result:
            model_name = metadata_result[0]["MODEL_NAME"]
        else:
            model_name = "UNKNOWN"
            session.sql(f"""
                INSERT INTO {prefilter_table_name} (
                    MODEL_NAME, FILENAME, FILESIZE, NUMBER_OF_PAGES, DATECREATED, COMMENT, STATUS, PROCESS_START_TIME, PROCESS_END_TIME
                ) VALUES (
                    ''UNKNOWN'', ''{relative_path}'', {file_size}, NULL, CURRENT_TIMESTAMP,
                    ''File skipped: Unknown folder type.'', ''SKIPPED'', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                )
            """).collect()
            continue  # Skip to the next file

        # Step 4: Skip files with size 0 bytes
        if file_size == 0:
            session.sql(f"""
                INSERT INTO {prefilter_table_name} (
                    MODEL_NAME, FILENAME, FILESIZE, NUMBER_OF_PAGES, DATECREATED, COMMENT, STATUS, PROCESS_START_TIME, PROCESS_START_TIME
                ) VALUES (
                    ''{model_name}'', ''{relative_path}'', {file_size}, NULL, CURRENT_TIMESTAMP,
                    ''File size is 0 bytes.'', ''SKIPPED'', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                )
            """).collect()
            continue

        try:
            # Step 5: Insert or update prefilter table for processing
            session.sql(f"""
                INSERT INTO {prefilter_table_name} (
                    MODEL_NAME, FILENAME, FILESIZE, NUMBER_OF_PAGES, DATECREATED, COMMENT, STATUS, PROCESS_START_TIME
                ) SELECT 
                    ''{model_name}'', ''{relative_path}'', {file_size}, NULL, CURRENT_TIMESTAMP,
                    ''Validated Successfully'', ''NOT PROCESSED'', CURRENT_TIMESTAMP
                WHERE NOT EXISTS (
                    SELECT 1 FROM {prefilter_table_name} WHERE FILENAME = ''{relative_path}''
                )
            """).collect()

            # Step 6: Download the file from the stage and count pages
            session.file.get(stage_file_path, temp_dir)
            local_file_path = os.path.join(temp_dir, relative_path.split("/")[-1])

            if not os.path.exists(local_file_path):
                raise FileNotFoundError(f"File {relative_path} not found.")

            with open(local_file_path, "rb") as file:
                pdf_reader = PyPDF2.PdfReader(file)
                total_pages = len(pdf_reader.pages)

            # Update the prefilter table with page count
            session.sql(f"""
                UPDATE {prefilter_table_name}
                SET 
                    NUMBER_OF_PAGES = {total_pages},
                    STATUS = ''NOT PROCESSED'',
                    COMMENT = ''Page count updated successfully.'',
                    PROCESS_END_TIME = CURRENT_TIMESTAMP
                WHERE FILENAME = ''{relative_path}''
            """).collect()

        except Exception as e:
            # Handle errors during file processing
            session.sql(f"""
                UPDATE {prefilter_table_name}
                SET STATUS = ''ERROR'',
                    COMMENT = ''Processing failed: {str(e)}''
                WHERE FILENAME = ''{relative_path}''
            """).collect()
        
        finally:
            # Clean up the local file
            if os.path.exists(local_file_path):
                os.remove(local_file_path)

        processed_count += 1

    # Step 7: Drop the temporary table
    session.sql(f"DROP TABLE IF EXISTS {temp_table_name}").collect()
    return f"Processed a total of {processed_count} files successfully."
';

CREATE OR REPLACE PROCEDURE DS_DEV_DB.DOC_AI_SCHEMA.MANAGE_MANUAL_REVIEW_FILES()

RETURNS VARCHAR(16777216)

LANGUAGE JAVASCRIPT

EXECUTE AS CALLER

AS '

try {

    // Create temporary table for file tracking

    var create_temp_table = `

        CREATE OR REPLACE TEMPORARY TABLE temp_files_to_move AS

        SELECT FILENAME

        FROM DOCAI_PREFILTER

        WHERE STATUS = ''MANUAL REVIEW''`;

    snowflake.execute({ sqlText: create_temp_table });

    // Check if there are any files to process

    var check_files = `SELECT COUNT(*) AS file_count FROM temp_files_to_move`;

    var files_result = snowflake.execute({ sqlText: check_files });

    files_result.next();

    var file_count = files_result.getColumnValue(1);

    if (file_count === 0) {

        return "No files found with MANUAL_REVIEW status";

    }

    // Get the pattern string for file operations

    var get_pattern = `SELECT LISTAGG(FILENAME, ''|'') FROM temp_files_to_move`;

    var pattern_result = snowflake.execute({ sqlText: get_pattern });

    pattern_result.next();

    var file_pattern = pattern_result.getColumnValue(1);

    // Create the complete pattern string in JavaScript

    var complete_pattern = ''.*('' + file_pattern + '').*'';

    // Copy files to Manual_Review stage

    var copy_files = `COPY FILES INTO @Manual_Review 

                      FROM @INVOICE_DOCS

                      PATTERN = ''${complete_pattern}''`;

    snowflake.execute({ sqlText: copy_files });

    // Remove files from source stage

    var remove_files = `REMOVE @INVOICE_DOCS 

                       PATTERN = ''${complete_pattern}''`;

    snowflake.execute({ sqlText: remove_files });

    // Update status to Failed

    var update_status = `UPDATE DOCAI_PREFILTER

                        SET STATUS = ''FAILED''

                        WHERE STATUS = ''MANUAL REVIEW''

                        AND FILENAME IN (SELECT FILENAME FROM temp_files_to_move)`;

    var update_result = snowflake.execute({ sqlText: update_status });

    // Clean up temporary table

    var cleanup = `DROP TABLE IF EXISTS temp_files_to_move`;

    snowflake.execute({ sqlText: cleanup });

    return `Successfully processed ${file_count} files`;

} catch (err) {

    // Clean up temporary table in case of error

    try {

        snowflake.execute({ sqlText: `DROP TABLE IF EXISTS temp_files_to_move` });

    } catch (cleanup_err) {

        // Ignore cleanup errors

    }

    return `Failed to process files: ${err}`;

}

';

CREATE OR REPLACE PROCEDURE DS_DEV_DB.DOC_AI_SCHEMA.HANDLE_PDF_FILES()
RETURNS VARCHAR(16777216)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
EXECUTE AS OWNER
AS '
from snowflake.snowpark.session import Session
from datetime import datetime

def main(session: Session) -> str:
    try:
        # Define the table and stage names
        prefliter_table = "DS_DEV_DB.DOC_AI_SCHEMA.DOCAI_PREFILTER"
        metadata_table_name = "DS_DEV_DB.DOC_AI_SCHEMA.MODEL_METADATA"
        manual_stage = "@MANUAL_REVIEW"
        doc_stage = "@INVOICE_DOCS"
        extraction_table = "DocAI_OrderForm_Extraction"
        
        # Query to fetch all files with `NOT PROCESSED` status
        get_file_name_query = f"""
            SELECT 
                FILENAME, ROWID, FILESIZE, NUMBER_OF_PAGES
            FROM {prefliter_table}
            WHERE STATUS = ''NOT PROCESSED''
        """
        
        # Execute the query
        rows = session.sql(get_file_name_query).collect()
        
        # Check if there are records to process
        if not rows:
            return "No files to process."

        for row in rows:
            file_name = row["FILENAME"]  
            row_id = row["ROWID"]
            file_size_mb = float(row["FILESIZE"]) / (1024 * 1024)  # Convert bytes to MB
            number_of_pages = row["NUMBER_OF_PAGES"]

            try:
                # Extract folder name from the full file path
                folder_name = file_name.split("/")[0]  
                
                # Query metadata table to determine model and prediction type
                metadata_query = f"""
                    SELECT MODEL_NAME, PREDICTION_TYPE
                    FROM {metadata_table_name}
                    WHERE FOLDER_NAME = ''{folder_name}''
                    LIMIT 1
                """
                metadata_result = session.sql(metadata_query).collect()

                # If no matching metadata found, skip the file
                if not metadata_result:
                    session.sql(f"""
                        UPDATE {prefliter_table}
                        SET STATUS = ''SKIPPED'',
                            COMMENT = ''No matching metadata for folder {folder_name}.'',
                            PROCESS_END_TIME = CURRENT_TIMESTAMP
                        WHERE ROWID = ''{row_id}''
                    """).collect()
                    continue

                # Extract model details
                model_name = metadata_result[0]["MODEL_NAME"]
                prediction_type = metadata_result[0]["PREDICTION_TYPE"]

                # Check the file size and number of pages criteria
                if file_size_mb > 3 and number_of_pages > 25:
                    # Move files to manual_review stage
                    session.sql(f"""
                        COPY FILES INTO {manual_stage}
                        FROM {doc_stage}
                        FILES = (''{file_name}'')
                    """).collect()

                    # Update status to MANUAL REVIEW
                    session.sql(f"""
                        UPDATE {prefliter_table}
                        SET STATUS = ''MANUAL REVIEW'',
                            COMMENT = ''File moved to manual_review stage as it failed both criteria.'',
                            PROCESS_END_TIME = CURRENT_TIMESTAMP
                        WHERE ROWID = ''{row_id}''
                    """).collect()
                    continue  # Skip to the next file in the loop

                # Update status to IN PROGRESS
                session.sql(f"""
                    UPDATE {prefliter_table}
                    SET STATUS = ''IN PROGRESS'',
                        COMMENT = ''Processing in progress.''
                    WHERE ROWID = ''{row_id}''
                """).collect()

                # Record the start time for processing
                process_start_time = session.sql("SELECT CURRENT_TIMESTAMP").collect()[0][0]

                # Process files meeting criteria
                json_result = session.sql(f"""
                    SELECT DS_DEV_DB.DOC_AI_SCHEMA.{model_name}!PREDICT(
                        GET_PRESIGNED_URL({doc_stage}, ''{file_name}''), {prediction_type}
                    )
                """).collect()[0][0]

                # Insert into extraction table
                session.sql(f"""
                    INSERT INTO {extraction_table} (
                        RELATIVEPATH, Model_Name, Size, File_Url, JSON, Comments, Status, PROCESS_START_TIME, PROCESS_END_TIME
                    )
                    SELECT 
                        ''{file_name}'' AS FILENAME, 
                        ''{model_name}'' AS Model_Name,
                        {row["FILESIZE"]} AS Size, 
                        GET_PRESIGNED_URL({doc_stage}, ''{file_name}'') AS File_Url, 
                        PARSE_JSON(''{json_result}'') AS JSON,
                        ''File processed successfully.'' AS Comments,
                        ''NOT PROCESSED'' AS Status,
                        ''{process_start_time}'' AS PROCESS_START_TIME,
                        CURRENT_TIMESTAMP AS PROCESS_END_TIME
                """).collect()

                # Update status to PROCESSED
                session.sql(f"""
                    UPDATE {prefliter_table}
                    SET STATUS = ''PROCESSED'',
                        COMMENT = ''File processed and moved to {extraction_table}.''
                    WHERE ROWID = ''{row_id}''
                """).collect()

            except Exception as e:
                # Log error in extraction table
                session.sql(f"""
                    UPDATE {prefliter_table}
                    SET STATUS = ''ERROR'',
                        COMMENT = ''Error during processing: {str(e)}''
                    WHERE ROWID = ''{row_id}''
                """).collect()

        return "Files processed successfully."

    except Exception as e:
        return f"General Error: {str(e)}"
';

CREATE OR REPLACE PROCEDURE DS_DEV_DB.DOC_AI_SCHEMA.LOAD_MODEL_FLATTEN()
RETURNS VARCHAR(16777216)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
EXECUTE AS OWNER
AS
$$
import json
from snowflake.snowpark.session import Session

class ModelProcessor:

    def __init__(self, session, model_name):
        self.session = session
        self.model_name = model_name
        
        # Define the table and schema names as variables
        self.metadata_table = "DS_DEV_DB.DOC_AI_SCHEMA.MODEL_METADATA"
        self.extraction_table = "DS_DEV_DB.DOC_AI_SCHEMA.DocAI_OrderForm_Extraction"
        self.score_threshold_table = "DS_DEV_DB.DOC_AI_SCHEMA.SCORE_THRESHOLD"
        self.flatten_table = self.load_metadata()['FLATTEN_TABLE']
        self.failed_score_table = self.load_metadata()['FAILED_SCORE_TABLE']
        
        self.metadata = self.load_metadata()
        self.total_processed = 0
        self.total_failed = 0

    def load_metadata(self):
        """
        Load metadata for the specified model name.
        """
        query = f"""
            SELECT * FROM {self.metadata_table}
            WHERE MODEL_NAME = '{self.model_name.replace("'", "''")}'
        """
        result = self.session.sql(query).collect()
        if not result:
            raise ValueError(f"No metadata found for model: {self.model_name}")
        return result[0]

    def check_not_processed_status(self):
        """
        Check if there are records with STATUS = 'NOT PROCESSED' for the model.
        """
        query = f"""
            SELECT COUNT(*) AS COUNT
            FROM {self.extraction_table}
            WHERE STATUS = 'NOT PROCESSED' AND MODEL_NAME = '{self.model_name.replace("'", "''")}';
        """
        result = self.session.sql(query).collect()
        return result[0]['COUNT'] > 0 if result else False

    def load_thresholds(self):
        """
        Load thresholds for the specified model.
        """
        query = f"""
            SELECT SCORE_NAME, CAST(SCORE_VALUE AS FLOAT) AS SCORE_VALUE
            FROM {self.score_threshold_table}
            WHERE MODEL_NAME = '{self.model_name.replace("'", "''")}'
        """
        thresholds = self.session.sql(query).collect()
        if not thresholds:
            raise ValueError(f"No thresholds found for the model: {self.model_name}")
        return {row['SCORE_NAME']: row['SCORE_VALUE'] for row in thresholds}

    def load_table_schema(self):
        """
        Load the schema of the flatten table from metadata.
        """
        query = f"DESCRIBE TABLE DS_DEV_DB.DOC_AI_SCHEMA.{self.flatten_table}"
        schema = self.session.sql(query).collect()
        return {row['name'].upper() for row in schema}

    def insert_failed_history(self, filename, score_name, score_value, comments):
        """
        Insert failed validation details into the failed score history table.
        """
        insert_query = f"""
            INSERT INTO DS_DEV_DB.DOC_AI_SCHEMA.{self.failed_score_table} (
                SCORE_NAME, 
                SCORE_VALUE, 
                DATE_FAILED, 
                FILENAME, 
                COMMENTS
            ) VALUES (
                '{score_name.replace("'", "''")}', 
                {score_value}, 
                CURRENT_TIMESTAMP, 
                '{filename.replace("'", "''")}', 
                '{comments.replace("'", "''")}'
            );
        """
        self.session.sql(insert_query).collect()

    def insert_flatten_table(self, record, json_data, ocr_score, failed_fields, start_time, end_time):
        """
        Insert processed data into the flatten table.
        """
        insert_columns = ["RELATIVEPATH", "MODEL_NAME", "OCR_SCORE"]
        insert_values = [record["RELATIVEPATH"], self.model_name, ocr_score]

        for field, threshold in self.thresholds.items():
            if field == "ocrScore":
                continue

            field_score_col = f"{field.upper()}_SCORE"
            field_value_col = f"{field.upper()}_VALUE"

            if field_score_col in self.valid_columns and field_value_col in self.valid_columns:
                field_data = json_data.get(field, [])
                if not field_data:
                    print(f"Field '{field}' is missing in JSON. Inserting default values.")
                    insert_columns.extend([field_score_col, field_value_col])
                    insert_values.extend([0, "NULL"])
                    continue

                score = field_data[0].get("score", 0)
                concatenated_values = ", ".join(
                    [item.get("value", "").replace("'", "''") for item in field_data]
                )
                insert_columns.extend([field_score_col, field_value_col])
                insert_values.extend([score, concatenated_values])

        status = "FAILED" if failed_fields else "PROCESSED"
        comments = f"Failed: {', '.join(failed_fields)}" if failed_fields else "All scores passed"

        insert_columns.extend(["STATUS", "COMMENTS", "PROCESSED_TIMESTAMP", "PROCESS_START_TIME", "PROCESS_END_TIME"])
        insert_values.extend([status, comments, "CURRENT_TIMESTAMP()", start_time, end_time])

        columns = ", ".join(insert_columns)
        placeholders = ", ".join(
            ["?" if val != "CURRENT_TIMESTAMP()" else "CURRENT_TIMESTAMP()" for val in insert_values]
        )
        query = f"INSERT INTO DS_DEV_DB.DOC_AI_SCHEMA.{self.flatten_table} ({columns}) VALUES ({placeholders})"
        self.session.sql(query, [val for val in insert_values if val != "CURRENT_TIMESTAMP()"]).collect()

    def update_extraction_status(self, relative_path, status):
        """
        Update the status of the record in the extraction table.
        """
        query = f"""
            UPDATE {self.extraction_table}
            SET STATUS = '{status}'
            WHERE RELATIVEPATH = '{relative_path.replace("'", "''")}';
        """
        self.session.sql(query).collect()

    def process_record(self, record):
        """
        Process an individual record.
        """
        try:
            json_data = json.loads(record['JSON'])
            self.thresholds = self.load_thresholds()
            self.valid_columns = self.load_table_schema()

            process_start_time = self.session.sql("SELECT CURRENT_TIMESTAMP").collect()[0][0]
            ocr_score = float(json_data.get("__documentMetadata", {}).get("ocrScore", 0))

            failed_fields = []
            if ocr_score < self.thresholds.get("ocrScore", 0):
                failed_fields.append("OCR_Score")
                self.insert_failed_history(record["RELATIVEPATH"], "OCR_Score", ocr_score, "OCR_Score failed validation")

            for field, threshold in self.thresholds.items():
                if field == "ocrScore":
                    continue
                field_data = json_data.get(field, [])
                if not field_data:
                    print(f"Field '{field}' is not present in the JSON. Skipping validation.")
                    continue
                score = field_data[0].get("score", 0)
                if score < threshold:
                    failed_fields.append(field)
                    self.insert_failed_history(
                        record["RELATIVEPATH"], field, score, f"{field} failed validation"
                    )

            process_end_time = self.session.sql("SELECT CURRENT_TIMESTAMP").collect()[0][0]

            self.insert_flatten_table(record, json_data, ocr_score, failed_fields, process_start_time, process_end_time)

            self.update_extraction_status(record["RELATIVEPATH"], "PROCESSED")
            self.total_processed += 1 if not failed_fields else 0
            self.total_failed += 1 if failed_fields else 0

        except Exception as e:
            import traceback
            error_message = str(e)
            stack_trace = traceback.format_exc()
            update_comments_query = f"""
                UPDATE {self.extraction_table}
                SET STATUS = 'ERROR',
                    COMMENTS = 'Error: {error_message.replace("'", "''")} | StackTrace: {stack_trace.replace("'", "''")}'
                WHERE RELATIVEPATH = '{record["RELATIVEPATH"].replace("'", "''")}'
            """
            self.session.sql(update_comments_query).collect()
            print(f"Error processing record {record['RELATIVEPATH']}: {error_message}")
            self.total_failed += 1

    def process_all_records(self):
        """
        Process all records for the specified model.
        """
        records_query = f"""
            SELECT RELATIVEPATH, JSON
            FROM {self.extraction_table}
            WHERE STATUS = 'NOT PROCESSED' AND MODEL_NAME = '{self.model_name.replace("'", "''")}'
        """
        records = self.session.sql(records_query).collect()
        if not records:
            return f"No records to process for model {self.model_name}."

        for record in records:
            self.process_record(record)

        return f"Processed {self.total_processed} records. Failed to process {self.total_failed} records for model {self.model_name}."

def main(session: Session) -> str:
    meta_table = "DS_DEV_DB.DOC_AI_SCHEMA.MODEL_METADATA" 
    model_names = session.sql(f"SELECT MODEL_NAME FROM {meta_table}").collect()
    if not model_names:
        return "No models found in metadata."

    results = []
    for model in model_names:
        processor = ModelProcessor(session, model['MODEL_NAME'])
        if processor.check_not_processed_status():
            results.append(processor.process_all_records())
        else:
            results.append(f"No records with 'NOT PROCESSED' status for model {model['MODEL_NAME']}.")

    return "\n".join(results)
$$;


CREATE OR REPLACE PROCEDURE DS_DEV_DB.DOC_AI_SCHEMA.LOAD_MODEL_VALIDATED()
RETURNS VARCHAR(16777216)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
EXECUTE AS OWNER
AS
$$
def main(session):
    try:
        total_processed = 0

        # Fetch all models from MODEL_METADATA
        metadata_query = """
            SELECT FLATTEN_TABLE, VALIDATED_TABLE
            FROM DS_DEV_DB.DOC_AI_SCHEMA.MODEL_METADATA
        """

        metadata_result = session.sql(metadata_query).collect()

        if not metadata_result:
            return "No models found in MODEL_METADATA."

        # Loop through all models in metadata
        for model in metadata_result:
            flatten_table = model["FLATTEN_TABLE"]
            validated_table = model["VALIDATED_TABLE"]

            # Fetch the column names for the flatten table that end with '_VALUE'
            column_query = f"""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = '{flatten_table.upper()}' AND COLUMN_NAME LIKE '%_VALUE'
            """

            column_names_result = session.sql(column_query).collect()

            if not column_names_result:
                print(f"No value columns found in {flatten_table}. Skipping model {flatten_table}.")
                continue

            # Extract the column names for the insert query
            column_names = [col["COLUMN_NAME"] for col in column_names_result]
            
            # Include RELATIVEPATH in the column names for insertion
            column_names.insert(0, "RELATIVEPATH")  # Add RELATIVEPATH at the beginning

            # Prepare the list of columns to insert
            insert_columns = ", ".join(column_names)

            # Fetch all processed records from the flatten table dynamically
            select_query = f"""
                SELECT {', '.join(column_names)}, RELATIVEPATH
                FROM DS_DEV_DB.DOC_AI_SCHEMA.{flatten_table}
                WHERE STATUS = 'PROCESSED'
            """
            rows_to_insert = session.sql(select_query).collect()

            if not rows_to_insert:
                print(f"No records to process from {flatten_table}.")
                continue

            print(f"Found {len(rows_to_insert)} records to process in {flatten_table}.")

            # Helper function to handle NULL values and format them properly
            def handle_null(value):
                if isinstance(value, str):
                    return value.replace("'", "''") if value else "NULL"
                elif isinstance(value, (int, float)):
                    return str(value) if value is not None else "NULL"
                return "NULL"

            # Start the validation process time
            validation_start_time = session.sql("SELECT CURRENT_TIMESTAMP").collect()[0][0]

            # Process each record and insert into the validated table dynamically
            for record in rows_to_insert:
                try:
                    # Dynamically construct the values for the insert query
                    insert_values = ", ".join([f"'{handle_null(record[col])}'" for col in column_names])

                    # Prepare the insert query for the validated table
                    insert_query = f"""
                        INSERT INTO DS_DEV_DB.DOC_AI_SCHEMA.{validated_table} ({insert_columns}, PROCESS_START_TIME)
                        VALUES ({insert_values}, '{validation_start_time}')
                    """
                    session.sql(insert_query).collect()

                    # Update the record in flatten table to 'VALIDATED'
                    update_query = f"""
                        UPDATE DS_DEV_DB.DOC_AI_SCHEMA.{flatten_table}
                        SET STATUS = 'VALIDATED'
                        WHERE RELATIVEPATH = '{record["RELATIVEPATH"].replace("'", "''")}'
                    """
                    session.sql(update_query).collect()

                    total_processed += 1

                except Exception as e:
                    # Handle errors and update the record status to 'ERROR'
                    error_message = f"Error processing record {record['RELATIVEPATH']}: {str(e)}"
                    print(error_message)

                    update_error_query = f"""
                        UPDATE DS_DEV_DB.DOC_AI_SCHEMA.{flatten_table}
                        SET STATUS = 'ERROR',
                            COMMENTS = '{error_message.replace("'", "''")}'
                        WHERE RELATIVEPATH = '{record["RELATIVEPATH"].replace("'", "''")}'
                    """
                    session.sql(update_error_query).collect()

            # End the validation process time
            validation_end_time = session.sql("SELECT CURRENT_TIMESTAMP").collect()[0][0]

            # Update the validation end time in the validated table
            update_end_time_query = f"""
                UPDATE DS_DEV_DB.DOC_AI_SCHEMA.{validated_table}
                SET PROCESS_END_TIME = '{validation_end_time}'
                WHERE PROCESS_START_TIME = '{validation_start_time}'
            """
            session.sql(update_end_time_query).collect()

        return f"Successfully validated {total_processed} records across all models."

    except Exception as e:
        return f"Procedure failed: {str(e)}"
$$;

CREATE OR REPLACE PROCEDURE DS_DEV_DB.DOC_AI_SCHEMA.MOVEFILES_TO_SOURCE(selected_file VARCHAR)
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS '
try {
    var selectedFile = arguments[0];
    var escapedFileName = selectedFile.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    var completePattern = `.*${escapedFileName}.*`;

    var list_files_query = `LIST @manual_review PATTERN = ''${completePattern}''`;
    var files_list = snowflake.execute({ sqlText: list_files_query });

    var subfolder = null;
    while (files_list.next()) {
        var full_path = files_list.getColumnValue(1);
        var parts = full_path.split("/");
        if (parts.length > 1) {
            subfolder = parts[1]; // Extract the immediate subfolder
            break;
        }
    }

    if (!subfolder || (subfolder !== "Order" && subfolder !== "Delivery")) {
        throw `Invalid or missing subfolder for file "${selectedFile}". Allowed folders are "Order" and "Delivery".`;
    }

    var copy_file_query = `
        COPY FILES INTO @IGNOIRED_DOCS
        FROM @manual_review
        PATTERN = ''${completePattern}''`;
    snowflake.execute({ sqlText: copy_file_query });

    var remove_file_query = `
        REMOVE @manual_review
        PATTERN = ''${completePattern}''`;
    snowflake.execute({ sqlText: remove_file_query });

    return `File "${selectedFile}" successfully moved from manual_review to IGNOIRED_DOCS/${subfolder}.`;
} catch (err) {
    return `Failed to process file "${selectedFile}": ${err}`;
}
';


CREATE OR REPLACE PROCEDURE DS_DEV_DB.DOC_AI_SCHEMA.IGNOREFILES_TO_STAGE(selected_file VARCHAR)
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS '
try {
    // Fetch the selected_file parameter
    var selectedFile = arguments[0];

    // Escape special characters in the filename for regex
    var escapedFileName = selectedFile.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    // Create a regex pattern for the file
    var completePattern = `.*${escapedFileName}.*`;

    // List files to identify the subfolder
    var list_files_query = `
        LIST @manual_review PATTERN = ''${completePattern}''`;
    var files_list = snowflake.execute({ sqlText: list_files_query });

    var subfolder = null;
    while (files_list.next()) {
        var full_path = files_list.getColumnValue(1); // Get the full path of the file

        // Extract subfolder from the path
        var parts = full_path.split("/"); // Split the path into parts
        if (parts.length > 1) {
            subfolder = parts[1]; // Extract the subfolder name 
            break; // Exit loop once subfolder is identified
        }
    }

    // If no subfolder is identified, throw an error
    if (!subfolder) {
        throw `Subfolder not identified for file "${selectedFile}".`;
    }

    // Correctly rename the subfolder to "removed_<subfolder>"
    var renamedSubfolder = `removed_${subfolder}`;

    // Copy the file from manual_review stage to the renamed subfolder in IGNOIRED_DOCS stage
    var copy_file_query = `
        COPY FILES INTO @IGNOIRED_DOCS
        FROM @manual_review
        PATTERN = ''${completePattern}''`;
    snowflake.execute({ sqlText: copy_file_query });

    // Remove the file from manual_review stage
    var remove_file_query = `
        REMOVE @manual_review
        PATTERN = ''${completePattern}''`;
    snowflake.execute({ sqlText: remove_file_query });

    // Return success message
    return `File "${selectedFile}" successfully moved from manual_review to IGNOIRED_DOCS/${renamedSubfolder} stage.`;
} catch (err) {
    return `Failed to process file "${selectedFile}": ${err}`;
}
';


-------------------------------------------------------------------------------------

create or replace task DS_DEV_DB.DOC_AI_SCHEMA.PREPROCESSING
	warehouse=DS_DEV_WH
	schedule='1 MINUTE'
-- TARGET_COMPLETION_INTERVAL='180 M'
--SERVERLESS_TASK_MIN_STATEMENT_SIZE='SMALL' SERVERLESS_TASK_MAX_STATEMENT_SIZE='LARGE'
	when SYSTEM$STREAM_HAS_DATA('PREPROCESS_STREAM')
	as BEGIN
    CALL COUNT_PDF_PAGES_PROC();
END;
------------------------------------------------------------------
create or replace task DS_DEV_DB.DOC_AI_SCHEMA.EXTRACT_DATA
	warehouse=DS_DEV_WH
	schedule='1 MINUTE'
--TARGET_COMPLETION_INTERVAL='180 M'
--SERVERLESS_TASK_MIN_STATEMENT_SIZE='SMALL' SERVERLESS_TASK_MAX_STATEMENT_SIZE='LARGE'
	as BEGIN
    CALL Handle_PDF_Files();
END;

------------------------------------------------------------------
CREATE OR REPLACE TASK DS_DEV_DB.DOC_AI_SCHEMA.MANUAL_CHECKUP_FILES
WAREHOUSE = DS_DEV_WH
--TARGET_COMPLETION_INTERVAL='180 M'
--SERVERLESS_TASK_MIN_STATEMENT_SIZE='SMALL' SERVERLESS_TASK_MAX_STATEMENT_SIZE='LARGE'
AFTER DS_DEV_DB.DOC_AI_SCHEMA.EXTRACT_DATA
AS
BEGIN
    -- Call procedures for both models
    CALL DS_DEV_DB.DOC_AI_SCHEMA.MANAGE_MANUAL_REVIEW_FILES();
END;
------------------------------------------------------------------
CREATE OR REPLACE TASK DS_DEV_DB.DOC_AI_SCHEMA.FLATTEN_DATA
WAREHOUSE = DS_DEV_WH
--TARGET_COMPLETION_INTERVAL='180 M'
--SERVERLESS_TASK_MIN_STATEMENT_SIZE='SMALL' SERVERLESS_TASK_MAX_STATEMENT_SIZE='LARGE'
AFTER DS_DEV_DB.DOC_AI_SCHEMA.EXTRACT_DATA
AS
BEGIN
    -- Call procedures for both models
    CALL DS_DEV_DB.DOC_AI_SCHEMA.LOAD_MODEL_FLATTEN();
    
END;

------------------------------------------------------------------
CREATE OR REPLACE TASK DS_DEV_DB.DOC_AI_SCHEMA.VALIDATE_DATA
WAREHOUSE = DS_DEV_WH
--TARGET_COMPLETION_INTERVAL='180 M'
--SERVERLESS_TASK_MIN_STATEMENT_SIZE='SMALL' SERVERLESS_TASK_MAX_STATEMENT_SIZE='LARGE'
AFTER DS_DEV_DB.DOC_AI_SCHEMA.FLATTEN_DATA
AS
BEGIN
    -- Call procedures for both models
    CALL DS_DEV_DB.DOC_AI_SCHEMA.LOAD_MODEL_VALIDATED();
END;
------------------------------------------------------------------
