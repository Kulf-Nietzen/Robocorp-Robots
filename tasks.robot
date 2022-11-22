*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Robocorp.Vault
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs


*** Variables ***
${out}      ${CURDIR}${/}output${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=    Get Url from Vault
    ${CSV_PATH}=    Input form dialog
    Open the robot order website    ${url}
    ${ORDERS}=    Get orders    ${CSV_PATH}
    FOR    ${row}    IN    @{ORDERS}
        RUN KEYWORD AND CONTINUE ON FAILURE    Close the annoying modal
        RUN KEYWORD AND CONTINUE ON FAILURE    Fill the form    ${row}
        RUN KEYWORD AND CONTINUE ON FAILURE    Preview the robot
        RUN KEYWORD AND CONTINUE ON FAILURE    Submit the order
        TRY
            Store the receipt as a PDF file    ${row}[Order number]
        EXCEPT
            LOG    SERVER ERROR
            CONTINUE
        END
        RUN KEYWORD AND CONTINUE ON FAILURE    Take a screenshot of the robot    ${row}[Order number]
        RUN KEYWORD AND CONTINUE ON FAILURE
        ...    Embed the robot screenshot to the receipt PDF file
        ...    ${row}[Order number]
        RUN KEYWORD AND CONTINUE ON FAILURE    Go to order another robot
    END
    CLOSE BROWSER
    Create a ZIP file of the receipts


*** Keywords ***
Get Url from Vault
    ${secret}=    Get Secret    secret_name=zertifikat2_url
    ${url}=    SET VARIABLE    ${secret}[url]
    RETURN    ${url}

Input form dialog
    Add heading    Select a CSV
    Add file input
    ...    name=csvFile
    ...    source=C:\Users\acron\OneDrive\Desktop\Robotic\Robocorp\Zertifikate\Robocorp-Robots\
    ...    file_type=CSV (*.csv)
    ...    label=CSV File
    ${result}=    Run dialog
    RETURN    ${result.csvFile}[0]

Open the robot order website
    [Arguments]    ${url}
    OPEN AVAILABLE BROWSER    ${url}    maximized=True

Get orders
    [Arguments]    ${CSV_PATH}
    ${ORDERS}=    READ TABLE FROM CSV    ${CSV_PATH}    header=True    delimiters=,
    RETURN    ${ORDERS}

Close the annoying modal
    TRY
        CLICK BUTTON    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    EXCEPT
        LOG    NO BUTTON
    END

Fill the form
    [Arguments]    ${row}
    SELECT FROM LIST BY INDEX    //*[@id="head"]    ${row}[Head]
    ${VALUE_BODY}=    GET ELEMENT ATTRIBUTE    //*[@id="id-body-1"]    value
    IF    ${VALUE_BODY} == ${row}[Body]    CLICK ELEMENT    //*[@id="id-body-1"]
    ${VALUE_BODY}=    GET ELEMENT ATTRIBUTE    //*[@id="id-body-2"]    value
    IF    ${VALUE_BODY} == ${row}[Body]    CLICK ELEMENT    //*[@id="id-body-2"]
    ${VALUE_BODY}=    GET ELEMENT ATTRIBUTE    //*[@id="id-body-3"]    value
    IF    ${VALUE_BODY} == ${row}[Body]    CLICK ELEMENT    //*[@id="id-body-3"]
    ${VALUE_BODY}=    GET ELEMENT ATTRIBUTE    //*[@id="id-body-4"]    value
    IF    ${VALUE_BODY} == ${row}[Body]    CLICK ELEMENT    //*[@id="id-body-4"]
    ${VALUE_BODY}=    GET ELEMENT ATTRIBUTE    //*[@id="id-body-5"]    value
    IF    ${VALUE_BODY} == ${row}[Body]    CLICK ELEMENT    //*[@id="id-body-5"]
    ${VALUE_BODY}=    GET ELEMENT ATTRIBUTE    //*[@id="id-body-6"]    value
    IF    ${VALUE_BODY} == ${row}[Body]    CLICK ELEMENT    //*[@id="id-body-6"]

    INPUT TEXT    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    INPUT TEXT    //*[@id="address"]    ${row}[Address]

Preview the robot
    TRY
        CLICK BUTTON    xpath://*[@id="preview"]
    EXCEPT
        LOG    NO BUTTON
    END

Submit the order
    TRY
        CLICK BUTTON    xpath://*[@id="order"]
    EXCEPT
        LOG    NO BUTTON
    END

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    ${HTML_BODY}=    GET ELEMENT ATTRIBUTE    locator=//*[@id="receipt"]    attribute=outerHTML
    HTML TO PDF    ${HTML_BODY}    ${out}${orderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    SCREENSHOT    //*[@id="robot-preview-image"]    ${out}${orderNumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${Order number}
    OPEN PDF    ${out}${Order number}.pdf
    ${FILE_LIST}=    CREATE LIST    ${out}${Order number}.pdf    ${out}${Order number}.png
    ADD FILES TO PDF    files=${FILE_LIST}    target_document=${out}${Order number}.pdf    append=False
    CLOSE PDF

Go to order another robot
    TRY
        CLICK BUTTON    //*[@id="order-another"]
    EXCEPT
        LOG    NO BUTTON
    END

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${out}/PDFs.zip
    ${files}=    Find files    ${out}*.png
    FOR    ${file}    IN    @{files}
        REMOVE FILE    ${file}
    END
    ARCHIVE FOLDER WITH ZIP    ${out}    ${zip_file_name}
