# Taro

Taro is a utility belt of functions to work with document files in Julia. It uses [Apache Tika](http://tika.apache.org/) and [Apache POI](http://poi.apache.org) (via [JavaCall](http://aviks.github.io/JavaCall.jl/)) to process the files. Current functionality includes the ability to read a DataFrame off an Excel sheet and the ability to extract text and metadata from a wide variety of document formats. It also uses [Apache FOP](https://xmlgraphics.apache.org/fop/) to generate PDF from `XSL-FO` files. 

[![Build Status](https://travis-ci.org/aviks/JavaCall.jl.png)](https://travis-ci.org/aviks/Taro.jl)

[![Taro](http://pkg.julialang.org/badges/Taro_0.3.svg)](http://pkg.julialang.org/?pkg=Taro&ver=release)

[![Taro](http://pkg.julialang.org/badges/Taro_0.4.svg)](http://pkg.julialang.org/?pkg=Taro&ver=nightly)



##Installation

```julia
Pkg.add("Taro")
```

On installation, the `tika-app-1.4.jar` file will be downloaded from *Maven Central*

##Usage

```julia
using Taro
Taro.init()
```

##API

### Read Excel files 
```
Taro.readxl(filename::String, sheet, region::String; 
        header::Bool = true, nastrings::Vector = ASCIIString["", "NA"], 
        truestrings::Vector = ASCIIString["T", "t", "TRUE", "true"],
        falsestrings::Vector = ASCIIString["F", "f", "FALSE", "false"], colnames::Vector = UTF8String[])
```
The `sheet` parameter can be `String` in which case it is interpreted as the sheet name. Alteratively, it could be an `Integer` which would be (a `0-` based) sheet number. 

The `sheet` parameter can be omitted, in which case the first sheet (index `0`) in the workbook is selected. 
```
Taro.readxl(filename::String, region::String; optional_config...)
```

The readxl function returns a dataframe from the contents of an MS Excel file. The sheet and region containing the data should be specified. By default, a header row is expected, which must consist only of strings. The `header` keyword argument should be set to `false` if no header is present in the data. 

###Extract raw content from document files

`Taro.extract(filename::String)`

The extract function retrieves document metadata and the body text of a document. It returns a Dict of metadata name value pairs, and a String with the text of the document. Supported formats include MS Office, Open Office and PDF documents. 

###Generate PDF files using FOP

Taro has an interface to the `Apache FOP` project. This allows you to generate professional quality PDF files from `XSL-FO` layout definition templates. 
Please see the [FOP Documentation](https://xmlgraphics.apache.org/fop/) for details. 

`Taro.fo(inputFoFileName::String, outputPDFFileName::String)`

Convert the input `fo` file to a PDF.


##Examples

```jlcon

julia> testfile = joinpath(Pkg.dir(),"Taro","test","df-test.xlsx");

julia> Taro.readxl(testfile, "Sheet1", "B2:F10")
8x5 DataFrame:
            H1     H2     H3     H4    H5
[1,]       "a"    1.0    1.0    1.0 "a a"
[2,]       "b"    2.0    2.0    1.0 "b b"
[3,]       "c"     NA    3.0    0.0 "c c"
[4,]       "d"    4.0     NA     NA "d d"
[5,]       "e"    5.0    5.0    1.0 "e e"
[6,]        NA    6.0    6.0    1.0   " "
[7,]       "g"    7.0    7.0    1.0 "g g"
[8,]       "h"    8.0    8.0    1.0 "h h"


julia> Taro.readxl(testfile, "Sheet1", "B3:F10"; header=false)
8x5 DataFrame:
            x1     x2     x3     x4    x5
[1,]       "a"    1.0    1.0    1.0 "a a"
[2,]       "b"    2.0    2.0    1.0 "b b"
[3,]       "c"     NA    3.0    0.0 "c c"
[4,]       "d"    4.0     NA     NA "d d"
[5,]       "e"    5.0    5.0    1.0 "e e"
[6,]        NA    6.0    6.0    1.0   " "
[7,]       "g"    7.0    7.0    1.0 "g g"
[8,]       "h"    8.0    8.0    1.0 "h h"

julia> Taro.readxl(testfile, "Sheet1", "B3:F10"; header=false, nastrings=[" "])
8x5 DataFrame:
            x1     x2     x3     x4     x5
[1,]       "a"    1.0    1.0    1.0  "a a"
[2,]       "b"    2.0    2.0    1.0  "b b"
[3,]       "c"     NA    3.0    0.0  "c c"
[4,]       "d"    4.0     NA     NA  "d d"
[5,]       "e"    5.0    5.0    1.0  "e e"
[6,]        NA    6.0    6.0    1.0     NA
[7,]       "g"    7.0    7.0    1.0  "g g"
[8,]       "h"    8.0    8.0    1.0  "h h"

```

```jlcon
julia> testfile = joinpath(Pkg.dir(),"Taro","test","WhyJulia.docx")
"/Users/aviks/.julia/Taro/test/WhyJulia.docx"

julia> meta, body = Taro.extract(testfile);

julia> meta["Last-Save-Date"]
"2013-12-28T00:17:00Z"

julia> typeof(body)
UTF8String (constructor with 1 method)

julia> length(body)
2966
```


[![Build Status](https://travis-ci.org/aviks/Taro.jl.png)](https://travis-ci.org/aviks/Taro.jl)
