' Written by James Albert

' window setup
nomainwin
WindowWidth  = 400
WindowHeight = 800
UpperLeftX=600
UpperLeftY=300

'init log prompt
open "log" for text as #log
    #log "Liberty BASIC DB"
    #log "--------------------------"

WindowWidth  = 400
WindowHeight = 100
UpperLeftX=200
UpperLeftY=300

'global variable/array setup
dim actions$(4)
actionstr$ = "create report update delete"
for i=1 to 4
    actions$(i) = word$(actionstr$, i)
next

'set up global variables and arrays
dim filenames$(2), rowlist$(100, 4), varlist$(100, 2)
global filenames$, fieldstatement$, varcount, reporting, updating, deleting
reporting = 0
updating = 0
deleting = 0

'graphical setup
combobox #win.label, actions$(), [donothing], 5, 15, 75, 19
button #win.submit, "submit", [evalquery], UL, 85, 15

' alphabet array
characterstring$ = "a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z , / ; ' [ ] \ - = < > ? : { } | _ + ) ( * & ^ % $ # @ ! ~"
dim alphabet$(82), symchar$(30)
for i = 1 to 82
    alphabet$(i) = word$(characterstring$, i)
next

'dialog window instantiation
open "FileManager" for dialog as #win
    #win.label "selectindex 1"
    #win.submit "!setfocus"
    #win "trapclose [quitbox]"
    wait

'open .bas file with liberty basic gui
function openlb$(file$, switch$)
    'ex file$ = "Z:\home\user\dir\to\file.bas"
    'ex switch$ = "-T -A"
    run "C:\Program Files\Liberty BASIC v4.04\LIBERTY "+switch$+" "+file$
    openlb$ = "started "+file$+" with switches "+switch$
end function

'run python files (must have python installed
function python(file$)
    run "C:\Python27\python.exe "+file$
    python = 1
end function

'openstr and closestr are used so
'that they don't conflict with string commands
function openstr$()
    openstr$ = chr$(111)+chr$(112)+chr$(101)+chr$(110)
end function

function closestr$()
    closestr$ = chr$(99)+chr$(108)+chr$(111)+chr$(115)+chr$(101)
end function

'find path and file name from a given absolute path
function findname$(file$)
    pos = 1
    found = 0
    while found = 0
        newpos = instr(file$, "\", pos+1)
        if newpos > 0 then
            pos = newpos
        else
            found = 1
        end if
    wend
    filenames$(1) = right$(file$, len(file$) - pos)
    filenames$(2) = left$(file$, pos)
    findname$ = "file name "+filenames$(1)+" created..."
end function

'confirms if file exists
function doesexist(path$, file$)
    dim filespec$(10, 10)
    files path$, file$, filespec$()
    if val(filespec$(0, 0)) > 0 then
        doesexist = 1
    else
        doesexist = -1
    end if
end function

'clear tmp files if they're there
function cleartmp$()
    if doesexist(path$, "tmp.bas") = 1 then
        kill "tmp.bas"
    end if
    if doesexist(path$, "tmp.tkn") = 1 then
        kill "tmp.tkn"
    end if
    cleartmp$ = "tmp files deleted..."
end function

'bring up filedialog,
'confirms if exists,
'and must be new file.
'returns absolute path to file
function openfile$(new)
    [choose]
    on error goto [openfailed]
    filedialog "load file", "./", filename$
    #log findname$(filename$)
    fileexists = doesexist(filenames$(2), filenames$(1))
    if fileexists = 1 and new = 1 then
        notice "name a new file"
        goto [choose]
    end if
    opennewfile$ = filename$
end function

'close file in LB
function closefile$()
    close #win.file
    closefile$ = "#win.file closed..."
end function

'saves field segments
function addtofield$(field$)
    fieldstatement$ = fieldstatement$ + field$
    addtofield$ = field$+" added to field statement..."
end function

'tokenize .bas file
function tokenize$(path$)
    notice "tokenizing "+path$+"tmp.bas"
    logged = 0
    #log openlb$(path$+"tmp.bas", "-T -A")
    do
        if logged = 0 then #log "waiting for tmp.tkn to be generated..."
        logged = 1
    loop until doesexist(path$, "tmp.tkn") = 1
    run path$+"tmp.tkn"
    tokenize$ = "tmp.tkn created..."
end function

'generate tmp.bas file
function runtmp$(new)
    if new = 1 then
        open "tmp.bas" for output as #outbas
    end if
    print #outbas, "nomainwin"
    print #outbas, "WindowWidth = 600"
    print #outbas, "WindowHeight = 480"
    print #outbas, "UpperLeftX=int((DisplayWidth-WindowWidth)/2)"
    print #outbas, "UpperLeftY=int((DisplayHeight-WindowHeight)/2)"
    print #outbas, openstr$()+" "+chr$(34)+filenames$(1)+chr$(34)+" for random as #1 len=100"
    if len(fieldstatement$) > 0 then
        field$ = fieldstatement$
    else
        if reporting = 0 and updating = 0 and deleting = 0 then
            field$ = "field #1,_"
        else
            field$ = ""
        end if
    end if
    print #outbas, field$
    runtmp$ = "tmp.bas file created..."
end function

'loads a file in LB
function loadfile$()
    'on error goto [loadfailed]
    filedialog "open file", "./", file$
    #log findname$(file$)
    loadfile$ = filename$+" loaded in LB..."
end function

'append fieldstatement$ to db
function appendfield$(file$)
    if len(fieldstatement$) > 0 then
        print #outbas, openstr$()+" "+chr$(34)+file$+chr$(34)+" for append as #appfield"
        print #outbas, "print #appfield, "+ chr$(34)+chr$(34)
        print #outbas, "print #appfield, "+ chr$(34)+fieldstatement$+chr$(34)
        print #outbas, closestr$()+" #appfield"
        print #outbas, "end"
        appendfield$ = "field statment appended to db..."
    else
        appendfield$ = "lack of field statement caused an error..."
    end if
end function

'define given field variables
function definefields$(deleting)
    for n=1 to varcount
        if not(deleting) then
            prompt rowlist$(n, 3)+" = "; value$
        else
            if instr(rowlist$(n, 3), "$") > 0 then
                value$ = ""
            else
                value$ = "0"
            end if
        end if
        varlist$(n,1) = rowlist$(n, 3)
        varlist$(n,2) = value$
        print #outbas, rowlist$(n, 3)+" = "+rowlist$(n, 4)+value$+rowlist$(n, 4)
    next
    definefields$ = "field variables are set..."
end function

function copyarray$(byref t1$, byref t2$, alloc)
    for i=1 to alloc
        if len(t1$(i)) <> 0 then
            t2$(i) = t1$(i)
        else
            i = alloc
        end if
    next
    copyarray$ = "arrays copied"
end function

function split$(string$, dlmt$)
    dim splitlist$(100)
    checking = 1
    occurance = 0
    oldstring$ = string$
    while checking = 1
        splitpoint = instr(string$, dlmt$)
        if splitpoint > 0 then
            occurance = occurance + 1
            splitlist$(occurance) = left$(string$, splitpoint-1)
            string$ = right$(string$, len(string$)-splitpoint)
        else
            if occurance > 0 then
                splitlist$(occurance+1) = string$
            end if
            checking = 0
        end if
    wend
    split$ = "split "+oldstring$+" at "+dlmt$+"..."
end function

function getfieldvars$(field$)
    dim fieldvars$(100), fieldblocks$(100)
    currvar = 1
    if len(field$) = 0 then
        field$ = fieldstatement$
    end if
    #log split$(field$, ",")
    for i=1 to 100
        if len(splitlist$(i)) <> 0 then
            fieldblocks$(i) = splitlist$(i)
        else
            i = 100
        end if
    next
    for i=1 to 100
        dim dclrs$(4)
        if len(fieldblocks$(i)) > 0 then
            if i <> 1 then
                #log split$(fieldblocks$(i), " ")
                for n=1 to 3
                    if len(splitlist$(n+1)) <> 0 then
                        dclrs$(n) = splitlist$(n+1)
                    else
                        n = 3
                    end if
                next
                rowlist$(currvar, 3) = dclrs$(3)
                if instr(dclrs$(3), "$") > 0 then
                    rowlist$(currvar, 4) = chr$(34)
                else
                    rowlist$(currvar, 4) = ""
                end if
                fieldvars$(currvar) = dclrs$(3)
                currvar = currvar + 1
            end if
        else
            varcount = currvar - 1
            i = 100
        end if
    next
    getfieldvars$ = "field variables obtained..."
end function

function getfield$()
    file$ = filenames$(1)
    open file$ for input as #retfield
        dim loadedlines$(1000)
            curline = 0
            while not(eof(#retfield))
                 curline = curline + 1
                 loadedlines$(curline) = inputto$(#retfield, chr$(10))
            wend
        field$ = loadedlines$(curline)
        close #retfield
    getfield$ = field$
end function

'update/insert values
function update$(uponcreating, deleting)
    if not(uponcreating) then
        field$ = getfield$()
        #log getfieldvars$(field$)
    end if
    #log definefields$(deleting)
    prompt "at which index?"; index$
    print #outbas, field$
    print #outbas, "put #1, "+index$
    print #outbas, closestr$()+" #1"
    #log appendfield$(filenames$(1))
    close #outbas
    #log tokenize$(filenames$(2))
    update$ = "db updated..."
end function

'delete by index
function delete$()
    #log update$(0, 1)
    delete$ = "deleted row..."
end function

'report values from table at index
function report$()
    prompt "at which index?"; index
    field$ = getfield$()
    print #outbas, field$
    #log getfieldvars$(field$)
    varstr$ = chr$(34)+chr$(34)
    for i=1 to 100
        if len(fieldvars$(i)) <> 0 then
            if instr(fieldvars$(i), "$") = 0 then
                fieldvars$(i) = "str$("+fieldvars$(i)+")"
            end if
            varstr$ = varstr$ + "+" + fieldvars$(i) + "+chr$(10)+chr$(10)"
        else
            i = 100
        end if
    next
    print #outbas, "gettrim #1, "+str$(index)
    print #outbas, "statictext #report.label, "+varstr$+", 10, 10, 300, 300"
    print #outbas, "open "+chr$(34)+"report table"+chr$(34)+" for dialog as #report"
    print #outbas, "#report "+chr$(34)+"trapclose [quit]"+chr$(34)
    print #outbas, "wait"
    print #outbas, "[quit]"
    print #outbas, closestr$()+" #report"
    print #outbas, closestr$()+" #1"
'    #log appendfield$(filenames$(1))
    close #outbas
    #log tokenize$(filenames$(2))
    report$ = "db report obtained..."
end function

'create new db
function create$()
    path$ = filenames$(2)
    file$ = filenames$(1)
    #log cleartmp$()
    #log runtmp$(1)
    #log addtofield$("field #1, ")
    creating = 1
    defining = 1
    i = 1
    rowstr$ = ""
    endstr$ = ", "
    while creating = 1
        prompt "length of field "+str$(i); length$
        rowlist$(i, 1) = length$
        prompt "field "+str$(i); row$
        rowlist$(i, 3) = row$
        confirm "is this a string?"; isstring$
        confirm "add another?"; cont$
        if cont$ = "no" then
            creating = 0
            endstr$ = ""
        end if
        if isstring$ = "yes" then
            type$ = "$"
            dlmt$ = chr$(34)
        else
            type$ = ""
            dlmt$ = ""
        end if
        rowlist$(i, 3) = rowlist$(i, 3)+type$
        rowlist$(i, 4) = dlmt$
        newrow$ = length$+" as "+rowlist$(i, 3)+endstr$
        #log addtofield$(newrow$)
        print #outbas, newrow$;
        i = i + 1
    wend
    varcount = i - 1
    print #outbas, ""
    #log update$(1, 0)
    kill "tmp.bas"
    kill "tmp.tkn"
    create$ = "db created..."
end function

function clearvars$()
    fieldstatement$ = ""
    dim filenames$(2), rowlist$(100, 4), varlist$(100, 2)
    filenames$ = ""
    fieldstatement$ = ""
    varcount = 0
    reporting = 0
    updating = 0
    deleting = 0
end function

'error handling
[loadfailed]
    notice "you already have a file loaded. we're closing it now. try again"
    close #win.file
    resume

[donothing]
    wait

[openfailed]
    notice "error occured opening file"
    close #win.file
    resume

'evaluate query
[evalquery]
    #log cleartmp$()
    print #win.label, "contents? cmd$"
    if cmd$ = "create" then
        filepath$ = openfile$(1)
        #log create$()
    end if
    if cmd$ = "update" or cmd$ = "report" or cmd$ = "delete" then
        if len(filenames$(1)) = 0 then
            #log loadfile$()
        end if
    end if
    if cmd$ = "delete" then
        deleting = 1
        #log runtmp$(1)
        #log delete$()
        deleting = 0
    end if
    if cmd$ = "update" then
        updating = 1
        #log runtmp$(1)
        #log update$(0, 0)
        updating = 0
    end if
    if cmd$ = "report" then
        reporting = 1
        #log runtmp$(1)
        #log report$()
        reporting = 0
    end if
    #log cleartmp$()
    #log clearvars$()
    wait

'confirm quit
[quitbox]
    #log "quit requested"
    confirm "Are you sure you're done"; selection$
    if selection$ = "yes" then [quit]
    wait

'we're done
[quit]
    close #log
    close #win
    end
