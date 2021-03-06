module Taro

using JavaCall
using DataFrames
using DataArrays
using Compat

tika_jar = joinpath(Pkg.dir(), "Taro", "deps", "tika-app-1.10.jar")
avalon_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "avalon-framework-4.2.0.jar")
batik_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "batik-all-1.8.jar")
commons_io_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "commons-io-1.3.1.jar")
commons_logging_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "commons-logging-1.0.4.jar")
fontbox_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "fontbox-1.8.5.jar")
serializer_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "serializer-2.7.1.jar")
xalan_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "xalan-2.7.1.jar")
xerces_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "xercesImpl-2.7.1.jar")
xml_apis_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "xml-apis-1.3.04.jar")
xml_apis_ext_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "xml-apis-ext-1.3.04.jar")
xmlgraphics_common_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "lib", "xmlgraphics-commons-2.0.1.jar")

fop_jar = joinpath(Pkg.dir(), "Taro", "deps", "fop-2.0", "build", "fop.jar")

JavaCall.addClassPath(tika_jar)
JavaCall.addClassPath(avalon_jar)
JavaCall.addClassPath(commons_io_jar)
JavaCall.addClassPath(fontbox_jar)
JavaCall.addClassPath(batik_jar)
JavaCall.addClassPath(xmlgraphics_common_jar)
JavaCall.addClassPath(fop_jar)


JavaCall.addOpts("-Xmx256M")
JavaCall.addOpts("-Djava.awt.headless=true")

init() = JavaCall.init()

function extract(filename::AbstractString)
	JavaCall.assertloaded()
	File = @jimport java.io.File
	f=File((JString,), filename)
	FileInputStream = @jimport java.io.FileInputStream
	InputStream = @jimport java.io.InputStream
	is = FileInputStream((File,), f)
	Metadata = @jimport org.apache.tika.metadata.Metadata
	BodyContentHandler = @jimport org.apache.tika.sax.BodyContentHandler
	AutoDetectParser = @jimport org.apache.tika.parser.AutoDetectParser
	Tika = @jimport org.apache.tika.Tika
	tika = Tika((),)
	mimeType = jcall(tika, "detect",JString, (File,), f) 

	metadata=Metadata((),)
	ch=BodyContentHandler((),)
	parser=AutoDetectParser((),)

	jcall(metadata, "set", Void, (JString, JString), "Content-Type", mimeType)
	ParseContext = @jimport org.apache.tika.parser.ParseContext
	pc = ParseContext((),)
	ContentHandler = @jimport org.xml.sax.ContentHandler
	jcall(parser, "parse", Void, (InputStream, ContentHandler, Metadata, ParseContext), is, ch, metadata, pc)
	nm = jcall(metadata, "names", Array{JString,1}, (),)
    nm = map(bytestring, nm)
    vs=Array(AbstractString, length(nm))
    for i in 1:length(nm)
        vs[i] = jcall(metadata, "get", JString, (JString,), nm[i])
    end

    body = jcall(ch, "toString", JString, (),)

    return Dict(zip(nm, vs)) , body

end


const CELL_TYPE_NUMERIC = 0;
const CELL_TYPE_STRING = 1;
const CELL_TYPE_FORMULA = 2;
const CELL_TYPE_BLANK = 3;
const CELL_TYPE_BOOLEAN = 4;
const CELL_TYPE_ERROR = 5;

immutable ParseOptions{S <: ByteString}
    header::Bool
    nastrings::Vector{S}
    truestrings::Vector{S}
    falsestrings::Vector{S}
    colnames::Vector{Symbol}
    coltypes::Vector{Any}
    skipstart::Int
    skiprows::Vector{Int}
    skipblanks::Bool
end

#Cant use optional arguments since our API was already set with sheet as the second param.
readxl(filename::AbstractString, range::AbstractString;  opts...) = readxl(filename, 0, range; opts...)

function readxl(filename::AbstractString, sheet, range::AbstractString; 
				   header::Bool = true,
                   nastrings::Vector = ASCIIString["", "NA"],
                   truestrings::Vector = ASCIIString["T", "t", "TRUE", "true"],
                   falsestrings::Vector = ASCIIString["F", "f", "FALSE", "false"],
                   colnames::Vector = Symbol[],
                   coltypes::Vector{Any} = Any[],
                   skipstart::Int = 0,
                   skiprows::Vector{Int} = Int[],
                   skipblanks::Bool = true)

		
		# Set parsing options
    o = ParseOptions(header, 
                     nastrings, truestrings, falsestrings,
                     colnames, coltypes,
                     skipstart, skiprows, skipblanks)

     r=r"([A-Za-z]*)(\d*):([A-Za-z]*)(\d*)"
     m=match(r, range)
     startrow=parse(Int, m.captures[2])-1
     startcol=colnum(m.captures[1])
     endrow=parse(Int, m.captures[4])-1
     endcol=colnum(m.captures[3])

     if (startrow > endrow ) || (startcol>endcol)
     	error("Please provide rectangular region from top left to bottom right corner")
     end

    readxl(filename, sheet, startrow, startcol, endrow, endcol, o)
end

function getSheet(book::JavaObject , sheetName::AbstractString) 
    Sheet = @jimport org.apache.poi.ss.usermodel.Sheet
    jcall(book, "getSheet", Sheet, (JString,), sheetName) 
end

function getSheet(book::JavaObject , sheetNum::Integer) 
    Sheet = @jimport org.apache.poi.ss.usermodel.Sheet
    jcall(book, "getSheetAt", Sheet, (jint,), sheetNum) 
end



function readxl(filename::AbstractString, sheetname, startrow::Int, startcol::Int, endrow::Int, endcol::Int, o )
	JavaCall.assertloaded()
	File = @jimport java.io.File
	f=File((JString,), filename)
	WorkbookFactory = @jimport org.apache.poi.ss.usermodel.WorkbookFactory
	Workbook = @jimport org.apache.poi.ss.usermodel.Workbook
	Sheet = @jimport org.apache.poi.ss.usermodel.Sheet
	Row = @jimport org.apache.poi.ss.usermodel.Row
	Cell = @jimport org.apache.poi.ss.usermodel.Cell

	book = jcall(WorkbookFactory, "create", Workbook, (File,), f)
    if isnull(book) ; error("Unable to load Excel file: $filename"); end
	sheet = getSheet(book, sheetname)
    if isnull(sheet); error("Unable to load sheet: $sheetname in file: $filename"); end	
    cols = endcol-startcol+1
	
	if o.header
		row = jcall(sheet, "getRow", Row, (jint,), startrow)
		if !isnull(row)
			resize!(o.colnames,cols)
			for j in startcol:endcol 
				cell = jcall(row, "getCell", Cell, (jint,), j)
				if !isnull(cell)
					o.colnames[j-startcol+1] = DataFrames.makeidentifier(jcall(cell, "getStringCellValue", JString, (),))
				end
			end
		end
		startrow = startrow+1
	end

	rows = endrow-startrow +1
	columns = Array(Any, cols)
	for j in startcol:endcol 
		values = Array(Any, rows)
		missing = falses(rows)
		for i in startrow:endrow
			row = jcall(sheet, "getRow", Row, (jint,), i)
			if isnull(row); missing[i-startrow+1]=true ; continue; end 
			cell = jcall(row, "getCell", Cell, (jint,), j)
			if isnull(cell); missing[i-startrow+1]=true ; continue; end
			celltype = jcall(cell, "getCellType", jint, (),)
			if celltype == CELL_TYPE_FORMULA
				celltype = jcall(cell, "getCachedFormulaResultType", jint, (),)
			end

			if celltype == CELL_TYPE_BLANK || celltype == CELL_TYPE_ERROR
				missing[i-startrow+1]=true 
			elseif celltype == CELL_TYPE_BOOLEAN
				values[i-startrow+1] = (jcall(cell, "getBooleanCellValue", jboolean, (),) == JavaCall.JNI_TRUE) 
			elseif celltype == CELL_TYPE_NUMERIC
				values[i-startrow+1] = jcall(cell, "getNumericCellValue", jdouble, (),)
			elseif celltype == CELL_TYPE_STRING
				value = jcall(cell, "getStringCellValue", JString, (),)
				if value in o.nastrings
					missing[i-startrow+1]=true
				elseif value in o.truestrings
					values[i-startrow+1] = true
				elseif value in o.falsestrings
					values[i-startrow+1] = false 
				else 
					values[i-startrow+1] = value 
				end
			else 
				warn("Unknown Cell Type")
				missing[i-startrow+1]=true
			end

		end
		columns[j-startcol+1] = DataArray(values, missing)

	end
	if isempty(o.colnames)
        return DataFrame(columns, DataFrames.gennames(cols))
    else
        return DataFrame(columns, o.colnames)
    end
end

function colnum(col::AbstractString)
	cl=uppercase(col)
	r=0
	for c in cl
		r = (r * 26) + (c - 'A' + 1)
	end
	return r-1
end

include("fop.jl")


end # module
