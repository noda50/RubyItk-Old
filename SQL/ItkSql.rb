#! /usr/bin/env ruby
## -*- mode: ruby -*-

require 'pp' ;
require 'mysql' ;
require 'parsedate' ;
require 'date' ;

$LOAD_PATH.push("~/lib/ruby") ;

require 'WithConfParam.rb' ;
require 'Geo2DGml.rb' ;
require 'TimeDuration.rb' ;

$verbosep = false ;

##======================================================================
module ItkSql
  extend(self) ;

  ##==================================================
  class TableDef < WithConfParam ;

    ##::::::::::::::::::::::::::::::
    DefaultConf = {
      :host => 'localhost',
      :dbName => 'foo',
      :tableName => 'bar',
      :rootUser => 'root',
      :rootPass => '',
      :user => nil,
      :pass => nil,
      :columnList => [],
      nil => nil } ;


    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :host, true ;
    attr :dbName, true ;
    attr :tableName, true ;
    attr :rootUser, true ;
    attr :rootPass, true ;
    attr :user, true ;
    attr :pass, true ;
    attr :columnList, true ;
    attr :columnTable, true ;
    attr :columnTableByName, true ;

    ##------------------------------
    def initialize(conf = {})
      super(conf) ;

      @host = getConf(:host) ;
      @dbName = getConf(:dbName) ;
      @tableName = getConf(:tableName) ;
      @rootUser = getConf(:rootUser) ;
      @rootPass = getConf(:rootPass) ;
      @user = getConf(:user) ;
      @pass = getConf(:pass) ;

      setColDef(getConf(:columnList)) ;
    end

    ##------------------------------
    def setColDef(colDefList)
      @columnList = [] ;
      @columnTable = {} ;
      @columnTableByName = {} ;

      addColDefList(colDefList) ;
    end

    ##------------------------------
    def addColDefList(colDefList)
      colDefList.each{|colDef|
        addColDef(colDef) ;
      }
    end

    ##------------------------------
    def addColDef(colDef)
      if(colDef.is_a?(ColDef))
        @columnList.push(colDef) ;
        @columnTable[colDef.tag] = colDef ;
        @columnTableByName[colDef.name] = colDef ;
      else
        addColDef(ColDef.new(*colDef)) ;
      end
    end        

    ##------------------------------
    def userFullName()
      "#{@user}@#{@host}" ;
    end

    ##------------------------------
    def getColByTag(tag)
      @columnTable[tag] ;
    end

    ##------------------------------
    def getColByName(name)
      @columnTableByName[name] ;
    end


  end ## class TableDef


  ##==================================================
  class ColDef
    include ItkSql ;

    attr :tag, true ;
    attr :name, true ;
    attr :type, true ;
    attr :isIndexed, true ;  ## = false, 
    attr :isKey, true ; ## = false | true | :auto
    attr :notNull, true ; ## = false
    attr :mysql, true ;

    ##------------------------------
    def initialize(name, type, isIndexed = false, 
                   isKey = false, notNull = false, 
                   *otherOpt) 
      setName(name) ;
      setType(type) ;
      @isIndexed = isIndexed ;
      @isKey = isKey ;    # if :auto, imply auto increment
      @notNull = notNull ;
      @otherOpts = otherOpt ;
    end

    ##------------------------------
    def setName(name)
      if(name.is_a?(Array))
        @tag = name[0] ;
        @name = name[1] ;
      elsif(name.is_a?(Symbol))
        @tag = name ;
        @name = name.to_s ;
      else
        @tag = name.to_s ;
        @name = name.to_s ;
      end
    end

    ##------------------------------
    def nameForSelect()
      if(@type == 'geometry')
        return "AsText(#{quotedName()})" ;
      else
        return quotedName() ;
      end
    end

    ##------------------------------
    def quotedName()
      "`#{@name}`"
    end

    ##------------------------------
    def setType(type, param = nil)
      case(type)
      when :int ;  	setType('integer') ;
      when :float ; 	setType('float') ;
      when :geo ; 	setType('geometry') ;
      when :bool ;	setType('boolean') ;
      when :date ;  	setType('date') ;
      when :time ;  	setType('time') ;
      when :datetime ;  setType('datetime') ;
      when :char8 ;	setType('varchar(8)') ;
      when :char16 ;	setType('varchar(16)') ;
      when :char32 ;	setType('varchar(32)') ;
      when :char64 ;	setType('varchar(64)') ;
      when :char128 ;	setType('varchar(128)') ;
      when :char256 ;	setType('varchar(256)') ;
      when :char512 ;	setType('varchar(512)') ;
      when :char1024 ;	setType('varchar(1024)') ;
      when :blob ;	setType('blob') ;
      else
        @type = type ;
      end
    end

    ##------------------------------
    def defstr()
      geoP = (@type == "geometry") ;

      coldef = quotedName() + " " + @type.to_s ;

      coldef += " key" if(@isKey) ;
      coldef += " auto_increment" if (@isKey == :auto) ;

      coldef += " not null" if (@notNull || (geoP && @isIndexed)) ;

      if(@otherOpts.size > 0) then
        coldef += " " + @otherOpts.join(" ") ;
      end

      if(@isIndexed) then
        coldef += "," ;
        if(geoP) then
          coldef += "spatial " ;
        end
        coldef += "index(" + quotedName() + ")" ;
      end
      return coldef ;
    end

    ##------------------------------
    def condstr(op, *args)
      case op
      when :eq ;
        return "#{quotedName()}=#{sqlValueForm(args[0])}" ;
      when :lt ;
        return "#{quotedName()}<#{sqlValueForm(args[0])}" ;
      when :le ;
        return "#{quotedName()}<=#{sqlValueForm(args[0])}" ;
      when :gt ;
        return "#{quotedName()}>#{sqlValueForm(args[0])}" ;
      when :ge ;
        return "#{quotedName()}>=#{sqlValueForm(args[0])}" ;
      when :geoIntersects ;
        return "INTERSECTS(#{quotedName()},#{sqlValueForm(args[0])})" ;
      else
        raise "Unknown operator for condstr: " + op.to_s ;
      end
    end

    ##------------------------------
    def scanValue(value)
      case (@type)
      when "integer" 
        return scanInteger(value) ;
      when "float"
        return scanFloat(value) ;
      when "boolean"
        return scanBoolean(value) ;
      when "date"
        return scanDate(value) ;
      when "time"
        return scanTimeDuration(value) ;
      when "datetime"
        return scanTime(value) ;
      when "geometry"
        return scanGeo2D(value) ;
      when "blob",/varchar/ 
        return scanString(value) ;
      end
    end

  end ## class ColDef

  ##::::::::::::::::::::::::::::::::::::::::::::::::::
  DefaultTableTable = {} ;
  ##--------------------------------------------------
  def defaultTableTable()
    if(self.is_a?(Module))
      self::DefaultTableTable ;
    else
      self.class.defaultTableTable() ;
    end
  end
  ##--------------------------------------------------
  def defineTable(conf = {})
    defaultTableTable()[self] = TableDef.new(conf) ;
  end
  ##::::::::::::::::::::::::::::::::::::::::::::::::::
  defineTable({}) ;

  ##--------------------------------------------------
  def defineAttributesByTableDef()
    colList = columnList() ;
    colList.each{|column|
      attr column.tag, true ;
    }
  end

  ##--------------------------------------------------
  def redefineTable(conf = {})
    currentConf = self.defaultTable().conf ;
    defineTable(currentConf.dup.update(conf)) ;
  end

  ##--------------------------------------------------
  def addColumnList(columnList)
    redefineTable({}) ;
    self.defaultTable().addColDefList(columnList) ;
  end

  ##--------------------------------------------------
  def defaultTable()
    # if self has an entry of table def,
    tab = defaultTableTable()[self] ;
    return tab if(tab) ;

    #if self is a class,
    if(self.is_a?(Module))
      self.ancestors.each{|mod|
        tab = defaultTableTable()[mod]
        return tab if(tab) ;
      }
      return nil ;
    else  # otherwise
      return self.class().defaultTable() ;
    end
  end

  ##--------------------------------------------------
  def dbHost()
    defaultTable().host() 
  end

  ##--------------------------------------------------
  def dbName()
    defaultTable().dbName() 
  end

  ##--------------------------------------------------
  def dbRootUser()
    defaultTable().rootUser() 
  end

  ##--------------------------------------------------
  def dbRootPass()
    defaultTable().rootPass() 
  end

  ##--------------------------------------------------
  def dbUser()
    defaultTable().user() 
  end

  ##--------------------------------------------------
  def dbPass()
    defaultTable().pass() 
  end

  ##--------------------------------------------------
  def tableName()
    defaultTable().tableName() ;
  end

  ##--------------------------------------------------
  def columnList()
    defaultTable().columnList() ;
  end

  ##--------------------------------------------------
  def sqlCols(includeKey = true)
    columnList().map(){|column| 
      ((!includeKey && column.isKey) ? nil : column.name)
    }.compact.join(',')  ;
  end

  ##--------------------------------------------------
  def sqlColsForSelect(includeKey = true)
    columnList().map(){|column| 
      ((!includeKey && column.isKey) ? nil : column.nameForSelect())
    }.compact.join(',')  ;
  end

  ##--------------------------------------------------
  def sqlKeyIsAssigned(value = true)
    @sqlKeyIsAssignedP = value ;
  end

  ##--------------------------------------------------
  def sqlKeyIsAssignedP()
    @sqlKeyIsAssignedP ;
  end

  ##--------------------------------------------------
  def sqlValueForm(value)
    if(value.nil?) then
      valueStr = "NULL" ;
    elsif(value.is_a?(Date)) then
      valueStr = "'" + value.to_s()+"'" ;
    elsif(value.is_a?(Time)) then
      valueStr = "'" + value.strftime("%Y-%m-%d %H:%M:%S") + "'" ;
    elsif(value.is_a?(TimeDuration)) then
      valueStr = "'" + ("%02d:%02d:%02d" % [value.getHour(nil).to_i,
                                            value.getMin().to_i,
                                            value.getSec().to_i]) + "'" ;
    elsif(value.is_a?(Geo2D::GeoObject))
      valueStr = "GeomFromText('" + value.to_Wkt() + "')" ;
    elsif(value.is_a?(String) || value.is_a?(Symbol))
#      valueStr = "'" + value.to_s + "'" ;
      valueStr = "'" + @mysql.quote(value.to_s) + "'";
    else
      valueStr = value.to_s ;
    end

    return valueStr ;
  end

  ##--------------------------------------------------
  def sqlValueListForm(valueList)
    if(valueList.is_a?(Array))
      return sqlValueListFormByArray(valueList) ;
    elsif(valueList.is_a?(Hash))
      return sqlValueListFormByHash(valueList) ;
    else
      raise "Arg of sqlValueListForm should be Array/Hash" ;
    end
  end

  ##--------------------------------------------------
  def sqlValueListFormByArray(valueList)
#     pp valueList ;
    valueStr = nil ;
    valueList.each{|value|
      if(valueStr.nil?) then
        valueStr = '' ;
      else
        valueStr += ',' ;
      end

      value = sqlValueForm(value) ;

      valueStr += value ;
    }
    return valueStr ;
  end

  ##--------------------------------------------------
  def sqlValueListFormByHash(valueList)
    valueStr = nil ;
    columnList().each{|coldef|
      val = valueList[coldef.tag] ;
      if(!(coldef.isKey && val.nil?)) 
        sqlKeyIsAssigned() if coldef.isKey ;

        if(valueStr.nil?) then
          valueStr = '' ;
        else
          valueStr += ',' ;
        end

        value = sqlValueForm(val) ;
        valueStr += value ;
      end
    }
    return valueStr ;
  end

  ##--------------------------------------------------
  def sqlValueListFormByAttributes()
    valueHash = {} ;
    columnList().each{|coldef|
      colname = coldef.tag
      valueHash[colname] = self.method(colname).call() ;
#      puts valueHash[colname]
    }
    sqlValueListFormByHash(valueHash) ;
  end

  ##--------------------------------------------------
  def sqlCondition(cond)
    if(cond.is_a?(String))
      return cond ;
    elsif(cond == true || cond == :true)
      return "true" ;
    elsif(cond.nil? || cond == false || cond == :false)
      return "false" ;
    elsif(cond.is_a?(Array))
      sqlConditionArray(*cond)
    else
      return cond ;
    end
  end

  ##--------------------------------------------------
  def sqlConditionArray(op, *args) ## (:op ::= :and, :or, :not, comp.op.)
    case op
    when :and ;
      return args.map{|arg| "(#{sqlCondition(arg)})"}.join("and") ;
    when :or ;
      return args.map{|arg| "(#{sqlCondition(arg)})"}.join("or") ;
    when :not ;
#      return "not(" + sqlConditionArray(args[0]) + ")" ;
      return "not(" + sqlCondition(args[0]) + ")" ;
    else ## suppose other is comp. op.
      column = defaultTable().getColByTag(args[0]) ;
      column.mysql = @mysql ;
      return column.condstr(op, *args[1..-1]) ;
    end
  end

$connect = 0 ;
  ##--------------------------------------------------
  def sqlConnect(user = dbUser(), 
                 password = dbPass(), 
                 dbName = dbName(), &block)
    if(!ItkSql.const_defined?('MysqlStab')) then
      ItkSql.const_set('MysqlStab',Mysql.init()) ;
    end

    begin
      mysql = MysqlStab.connect(dbHost(), user, password, dbName) ;
      yield(mysql) ;
    ensure
      if(mysql.nil?)
        raise ("Can't connect to MySQL server by [user=%s, pass=%s, host=%s, db=%s" %
               [user, password, dbHost(), dbName]) ;
      end
      mysql.close() if !mysql.nil?
    end
  end
  
  ##--------------------------------------------------
  def sqlMultiQuery(mysql, multiCom, verboseP = $verbosep)
    results = [] ;
    
    comList = nil ;
    if(multiCom.is_a?(String)) then
      comList = multiCom.split(/;/) ;
    elsif(multiCom.is_a?(Array)) then
      comList = multiCom ;
    else
      raise("sqlMultiQuery() can not handle commands: " + multiCom.to_s) ;
    end

    comList.each{|com|
      com.gsub!(/\n/,'') ;
      if(com !~ /^\s*$/) then
        puts com if(verboseP) ;
        res = mysql.query(com) ;
        if(res) then
          res.each{|values|
            p values if(verboseP) ;
            results.push(values) ;
          }
        end
      end
    }
    return results ;
  end

  ##--------------------------------------------------
  def sqlScript_InitializeDatabase()
    script = "drop database if exists `#{dbName()}` ;\n" ;
    script += "create database `#{dbName()}` ;\n" ;
    script += "show databases ; \n" ;
    script += "grant all privileges on `#{dbName()}`.* to `#{dbUser()}` ;\n" ;
    script += "flush privileges;\n" ;
    script += "use `#{dbName()}`;\n"
    script += "show tables ;\n" ;
    return script ;
  end

  ##--------------------------------------------------
  def sqlDo_InitializeDatabase()
    sqlConnect(dbRootUser(), dbRootPass(), nil) {|mysql|
      com = sqlScript_InitializeDatabase() ;
      sqlMultiQuery(mysql, com, true) ;
    }
  end

  ##--------------------------------------------------
  def sqlScript_SelectEntryByCond(cond = nil, orderBy = nil, groupBy = nil,
                                  limit = nil)
    script = "select #{sqlColsForSelect()} from `#{tableName()}`" ;

    script += " where #{sqlCondition(cond)}"  if(!cond.nil?) ;

    script += " order by #{orderBy.to_s}" if (!orderBy.nil?) ;
   
    script += " group by #{groupBy.to_s}" if (!groupBy.nil?) ;

    script += " limit #{limit.to_s}" if (!limit.nil?) ;

    return script ;

  end

  ##--------------------------------------------------
  def sqlQuery_SelectEntryByCond(mysql, 
                                 cond = nil, orderBy = nil, groupBy = nil,
                                 limit = nil,
                                 &block) 
    @mysql = mysql ;
    script = sqlScript_SelectEntryByCond(cond, orderBy, groupBy, limit) ;
    p script if $verbosep ;
    res = mysql.query(script) ;
    p res if $verbosep ;
    if(res) then
      res.each{|values|
        p values if $verbosep ;
        entry = self.new() ;
        entry.scanValues(values) ;
        yield(entry) ;
      }
    end
  end

  ##--------------------------------------------------
  def sqlScript_SelectAllChoiceOfColumn(columnName, ordered = false, 
                                        restCond = nil)
    script = "select (#{columnName}) from #{tableName()}" ;
    if(restCond) then
      script += " where #{sqlCondition(restCond)}" ;
    end
    script += " group by #{columnName}" ;
    if(ordered) then
      script += " order by #{columnName}" ;
    end
    return script ;
  end

  ##--------------------------------------------------
  def sqlQuery_SelectAllChoiceOfColumn(mysql, columnName, 
                                       ordered = false, 
                                       restCond = nil,  &block)
    @mysql = mysql ;

    com = sqlScript_SelectAllChoiceOfColumn(columnName, ordered, restCond) ;

    res = mysql.query(com) ;

    if(block) then
      res.each{|values|
        yield(values[0]);
      }
    else
      list = [] ;
      res.each{|values|
        list.push(values[0]) ;
      }
      return list ;
    end
  end

  ##--------------------------------------------------
  def sqlScript_CountByCond(mysql, cond = true)
    script = ("select count(*) from #{tableName()} " +
              "where #{sqlCondition(cond)}") ;
    return script ;

  end

  ##--------------------------------------------------
  def sqlQuery_CountByCond(mysql, cond = true)
    @mysql = mysql ;

    com = sqlScript_CountByCond(mysql, cond) ;

    p com if $verbosep;
    res = mysql.query(com) ;

    count = nil ;
    res.each{|values|
      count = values[0].to_i ;
    }
    return count ;
  end


  ##--------------------------------------------------
  def sqlScript_CountByColumnValue(mysql, columnTag, value, restCond = nil)
    cond = [:eq, columnTag, value] ;
    cond = [:and, cond, restCond] if(!restCond.nil?) 
    return sqlScript_CountByCond(mysql, cond) ;
  end

  ##--------------------------------------------------
  def sqlQuery_CountByColumnValue(mysql, columnName, value, restCond = nil)
    @mysql = mysql ;

    com = sqlScript_CountByColumnValue(mysql, columnName, value, restCond) ;

    p com if $verbosep ;
    res = mysql.query(com) ;

    count = nil ;
    res.each{|values|
      count = values[0].to_i ;
    }
    return count ;
  end

  ##--------------------------------------------------
  def sqlScript_SelectEnvelope(column, cond = true)
    var = '@geo' ;
    colName = column.to_s ;

    (["set #{var} = null",
      ("do (select count(" +
       "#{var} := if(ifnull(#{var},1)=1," +
       colName + "," +
       "Envelope(GeomFromText(" +
       "concat('GeometryCollection('," +
       "AsText(#{colName}),',',AsText(#{var}),')'))))) " +
       "from #{tableName()} " +
       "where #{sqlCondition(cond)})"),
      "select AsText(@geo)"]) ;
  end

  ##--------------------------------------------------
  def sqlQuery_SelectEnvelope(mysql, column, cond = true, &block)
    @mysql = mysql ;

    com = sqlScript_SelectEnvelope(column, cond) ;
    res = sqlMultiQuery(mysql,com) ;

#    p res ;

    if(res[0][0].nil?) then
      poly = nil ;
      bbox = nil ;
    else
      poly = Geo2D::GeoObject::scanWkt(res[0][0]) ;
      bbox = poly.bbox() ;
    end

    if(block)
      res.each{|values| block.call(bbox)}
    end

    bbox ;
  end

  ##--------------------------------------------------
  def sqlScript_SelectGeneric(target, cond = true)
    ("select #{target} from #{tableName()} where #{sqlCondition(cond)}") ;
  end

  ##--------------------------------------------------
  def sqlQuery_SelectGeneric(mysql, target, cond = true, &block)
    @mysql = mysql ;

    com = sqlScript_SelectGeneric(target, cond) ;
    p com if $verbosep ;
    res = mysql.query(com) ;

    if(block)
      res.each{|values| block.call(values)}
    else
      ans = [] ;
      res.each{|values| ans.push(values)} ;
    end
    ans ;
  end
      
  ##--------------------------------------------------
  def sqlScript_TableColumnDefList()
    columnList().map(){|column| column.defstr()}.join(",\n\t") ;
  end

  ##--------------------------------------------------
  def sqlScript_CreateTable()
    tabledef = "create table `#{tableName()}` " ;
    tabledef += "(#{sqlScript_TableColumnDefList()});" ;
    return tabledef ;
  end

  ##--------------------------------------------------
  def sqlScript_InitializeTable(forceP = true, showDetailP = true)
    script = "use `#{dbName()}` ;\n" ;

    script += "drop table if exists `#{tableName()}`;\n" if(forceP) ;

    script += sqlScript_CreateTable() + "\n" ;

    if(showDetailP) then
      script += "show tables;\n" ;
      script += "describe `#{tableName()}`;\n" ;
    end

    return script ;
  end

  ##--------------------------------------------------
  def sqlDo_InitializeTable(initDB = false, showDetailP = true)
    sqlDo_InitializeDatabase() if initDB ;
    sqlConnect() {|mysql|
      com = sqlScript_InitializeTable(true, showDetailP) ;
      sqlMultiQuery(mysql, com, true) ;
    }
  end

  ##--------------------------------------------------
  def sqlValues()
    raise ('sqlValues() has not implemented for class:' + self.class().to_s) ;
  end

  ##--------------------------------------------------
  def sqlScript_Insert(delayedp = false)
    values = sqlValues() ;
    ("insert #{(delayedp ? 'delayed' : '')} " + 
     "into `#{tableName()}` (#{sqlCols(sqlKeyIsAssignedP())}) " + 
     ## 上と下、どちらが正しいのか不明
#     "into `#{tableName()}` (#{sqlColsForSelect(sqlKeyIsAssignedP())}) " + 
     "values (#{values});") ;
  end

  ##--------------------------------------------------
  def sqlQuery_Insert(mysql, delayedp = false)
    @mysql = mysql ;

    com = sqlScript_Insert(delayedp) ;
    puts com if $verbosep ;
    mysql.query(com){|res|
      p res if @verbosep ;
    }
  end

  ##--------------------------------------------------
  def sqlCond_DuringServiceHour(column, serviceHour)
    [:and,
     [:gt, column, serviceHour.from],
     [:lt, column, serviceHour.to]] ;
  end

  ##--------------------------------------------------
  def scanValues
    raise ('scanValues() has not implemented for class:' + self.class().to_s) ;
  end

  ##--------------------------------------------------
  def scanValuesToAttributesByType(sqlVals)
    hash = scanValuesToHashByType(sqlVals) ;
    columnList().each{|column|
      colName = column.tag ;
      self.instance_variable_set('@' + colName.to_s, hash[colName]) ;
    }
  end

  ##--------------------------------------------------
  def scanValuesToArrayByType(sqlVals)
    valueList = [] ;

    colList = columnList() ;
    (0...colList.size).each{|k|
      value = colList[k].scanValue(sqlVals[k]) ;
      valueList.push(value) ;
    }
    
    return valueList ;
  end

  ##--------------------------------------------------
  def scanValuesToHashByType(sqlVals)
    valueTable = {} ;

    colList = columnList() ;
    (0...colList.size).each{|k|
      col = colList[k] 
      value = col.scanValue(sqlVals[k]) ;
      valueTable[col.tag] = value ;
    }
    
    return valueTable ;
  end

  ##--------------------------------------------------
  def scanTime(value)
    if(value.nil? || value == "NULL" || value == "null")
      return nil ;
    elsif(value.is_a?(Time))
      return value ;
    elsif(value.is_a?(String))
      return Time.local(*(ParseDate::parsedate(value))) ;
    else
      raise "Can't convert to Time object from: " + value.to_s ;
    end
  end

  ##--------------------------------------------------
  def scanDate(value)
    if(value.nil? || value == "NULL" || value == "null")
      return nil ;
    elsif(value.is_a?(Date))
      return value ;
    elsif(value.is_a?(Time))
      return Date.new(value.year, value.month, value.day) ;
    elsif(value.is_a?(String))
      timeValue = ParseDate::parsedate(value) ;
      return Date.new(*timeValue[0..2]) ;
    else
      raise "Can't convert to Time object from: " + value.to_s ;
    end
  end

  ##--------------------------------------------------
  def scanTimeDuration(value,range = (3..5))
    if(value.nil? || value == "NULL" || value == "null")
      return nil ;
    elsif(value.is_a?(TimeDuration))
      return value ;
    elsif(value.is_a?(String))
      timeValue = ParseDate::parsedate(value) ;
      duration = TimeDuration.new() ;
      duration.setTime(*timeValue[range]) ;
      return duration ;
    else
      raise "Can't convert to TimeDuration object from: " + value.to_s ;
    end
  end

  ##--------------------------------------------------
  def scanBoolean(value)
    case value 
    when nil, "NULL","null" ;
      return nil ;
    when "TRUE","true","1",1 ;
      return true ;
    when "FALSE","false","0",0 ;
      return false ;
    else
      raise "Can't convert to Boolean from: " + value.to_s ;
    end
  end
  
  ##--------------------------------------------------
  def scanInteger(value)
    case value 
    when nil, "NULL","null" ;
      return nil ;
    else
      return value.to_i ;
    end
  end

  ##--------------------------------------------------
  def scanFloat(value)
    case value 
    when nil, "NULL","null" ;
      return nil ;
    else
      return value.to_f ;
    end
  end

  ##--------------------------------------------------
  def scanString(value)
    case value 
    when nil, "NULL","null" ;
      return nil ;
    else
      return value.to_s ;
    end
  end

  ##--------------------------------------------------
  def scanGeo2D(value)
    Geo2D::GeoObject::scanWkt(value.to_s)
  end

end ## module TagCommon

########################################################################
########################################################################
## for test
########################################################################
########################################################################
if($0 == __FILE__) then

  ##----------------------------------------------------------------------
  def methodName(offset = 0)
    if  /`(.*)'/.match(caller[offset]) ;
      return $1
    end
    nil
  end

  ##======================================================================
  class Test

    ##--------------------------------------------------
    def timestamp()
      Time.now.strftime("%Y.%m%d.%H%M%S") ;
    end

    ##--------------------------------------------------
    def listTest()
      list = [] ;
      methods().sort().each{|m|
        list.push(m) if (m =~ /^test_/) ;
      }
      return list ;
    end

    ##--------------------------------------------------
    def test_A()
      Test_A_Foo::bar() ;
      Test_A_Baz::bar() ;
      Test_A_Baz.new().bar();
      Test_A_Baz2::bar() ;
      Test_A_Baz2.new().bar() ;
    end

    module Test_A_Foo
      extend self ;
      Bar = :bar

      def classConst(constName)
        if (self.is_a?(Module)) then
          self::const_get(constName) ; 
        else
          self.class()::const_get(constName) ;
        end
      end

      def bar()
        p [:bar, self, classConst(:Bar)] ;
      end
    end

    class Test_A_Baz
      extend Test_A_Foo
      include Test_A_Foo
      Bar = :baz
    end

    class Test_A_Baz2
      extend Test_A_Foo
      include Test_A_Foo
    end

    ##--------------------------------------------------
    class Test_B_Foo
      include ItkSql ;
      extend ItkSql ;
      defineTable({ :tableName => 'test_B',
                    :columnList => [[:col1, :int, true, true],
                                    [:col2, :int, true]] }) ;
    end

    class Test_B_Bar < Test_B_Foo
    end
      
    def test_B()
      p [ItkSql, ItkSql::defaultTable()] ;
      p [Test_B_Foo, Test_B_Foo::defaultTable()] ;
      p [Test_B_Foo, Test_B_Bar::defaultTable()] ;
    end

    ##--------------------------------------------------
    class Test_C_Foo
      include ItkSql ;
      extend ItkSql ;
      defineTable({ :tableName => 'test_C',
                    :columnList => [[:col1, :int, true, true],
                                    [:col2, :float, true],
                                    [:col3, :geo, true],
                                    [:col4, :datetime, true],
                                    [:col5, 'blob', false],
                                   ] }) ;
    end
    
    def test_C()
      p Test_C_Foo.sqlScript_InitializeDatabase() ;
      p Test_C_Foo.sqlScript_CreateTable() ;
    end

    ##--------------------------------------------------
    def test_D()
      Test_C_Foo.sqlDo_InitializeDatabase() ;
      Test_C_Foo.sqlDo_InitializeTable() ;
    end

    ##--------------------------------------------------
    class Test_E_Foo
      include ItkSql ;
      extend ItkSql ;
      defineTable({ :tableName => 'test_E',
                    :columnList => [[:col1, :int, true, true],
                                    [:col2, :float, true],
                                    [:col3, :geo, true],
                                    [:col4, :datetime, true],
                                    [:col5, :char64, true],
                                    [:col6, :blob, false],
                                   ] }) ;
      attr :values, true ;
      def sqlValues()
        sqlValueListForm(@values) ;
      end
      def scanValues(values)
        p values ;
        @values = scanValuesToArrayByType(values) ;
        p scanValuesToHashByType(values) ;
      end
    end
    def test_E()
      Test_E_Foo.sqlDo_InitializeDatabase() ;
      Test_E_Foo.sqlDo_InitializeTable() ;

      obj = Test_E_Foo.new() ;
      obj.values = [123,4.56, Geo2D::Point.new(7,8), Time.now(), 
                    'foo', "This is a test."] ;
      
      obj.sqlConnect(){|mysql|
        obj.sqlQuery_Insert(mysql) ;
        Test_E_Foo.sqlQuery_SelectEntryByCond(mysql){|entry|
          p entry ;
        }
      }

    end

    ##--------------------------------------------------
    class Test_F_Foo
      include ItkSql ;
      extend ItkSql ;
      defineTable({ :tableName => 'test_F_Foo',
                    :columnList => [[:col1, :int, true, true],
                                    [:col2, :float, true],
                                   ] }) ;
    end

    class Test_F_Bar < Test_F_Foo
      redefineTable({ :tableName => 'test_F_Bar' }) ;
      addColumnList([[:col3, :blob, false],
                     [:col4, :int, true]]) ;
    end

    def test_F()
      p Test_F_Foo.sqlDo_InitializeTable() ;
      p Test_F_Bar.sqlDo_InitializeTable() ;
    end

  end

  ##################################################
  ##################################################
  ##################################################

  myTest = Test.new() ;

  p ARGV ;
  testList = (ARGV.length > 0 ? ARGV : myTest.listTest()) ;

  testList.each{|testMethod|
    puts '-' * 50
    p [:try, testMethod] ;
    myTest.send(testMethod) ;
  }
  
end
