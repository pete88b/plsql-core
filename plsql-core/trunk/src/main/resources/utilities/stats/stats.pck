CREATE OR REPLACE PACKAGE stats
IS

  PROCEDURE run1 (
    p_label IN VARCHAR2 := NULL
  );

  PROCEDURE run2 (
    p_label IN VARCHAR2 := NULL
  );

  PROCEDURE stop ( 
    p_difference_threshold IN NUMBER := 0,
    p_stat_name IN VARCHAR2 := NULL
  );
    
END stats;
/

CREATE OR REPLACE PACKAGE BODY stats
IS
  -- %TYPE raises ORA-006502 numeric or value. bulk bind. error in define
  TYPE name_type IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;

  TYPE value_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  
  g_baseline_name name_type;
  g_baseline_value value_type;

  g_after1_name name_type;
  g_after1_value value_type;

  g_after2_name name_type;
  g_after2_value value_type;
  
  CURSOR stats
  IS
  SELECT 'STAT...' || a.name name, b.value
    FROM v$statname a, 
         v$mystat b
   WHERE a.statistic# = b.statistic#
   UNION ALL
  SELECT 'LATCH..' || name,  gets
    FROM v$latch;
  
  g_start_time NUMBER;

  g_run1_time NUMBER;
  g_run2_time NUMBER;

  g_run1_label VARCHAR2(100);
  g_run2_label VARCHAR2(100);
  
  eol CONSTANT VARCHAR2(1) := CHR(10);
  
  /* 
   * Private procedure pl
   */
  PROCEDURE pl (
    s IN VARCHAR2 := eol
  )
  IS 
  BEGIN
    dbms_output.put_line(s);

  END pl;
  
  /* 
   * run1
   */  
  PROCEDURE run1 (
    p_label IN VARCHAR2 := NULL
  )
  IS
  BEGIN
    --
    g_run1_label := p_label;
    
    -- List sessions which could affect the latch numbers
    FOR i IN (SELECT username, count(*) AS n
                FROM v$session
               WHERE username IS NOT NULL
               GROUP BY username)
    LOOP
      pl(i.username || ' has ' || i.n || ' sessions open.');

    END LOOP; 
    
    pl;
    
    -- No need make sure the index-by tables are empty as bulk collect will overwrite
    -- Get current stats. We'll compare stats after run1 to these numbers
    OPEN stats;
    FETCH stats BULK COLLECT INTO g_baseline_name, g_baseline_value;
    CLOSE stats;
    
    -- get start time
    g_start_time := dbms_utility.get_time;
    
  END run1;
  
  /* 
   * run2
   */  
  PROCEDURE run2 (
    p_label IN VARCHAR2
  )
  IS
  BEGIN
    --
    g_run2_label := p_label;

    -- Calculate the run1 time
    g_run1_time := (dbms_utility.get_time - g_start_time);
    
    -- Get current stats. We'll compare stats after run2 to these numbers
    OPEN stats;
    FETCH stats BULK COLLECT INTO g_after1_name, g_after1_value;
    CLOSE stats;
    
    -- re-set the start time for run2 as getting stats could take up some time
    g_start_time := dbms_utility.get_time;
  
  END run2;
  
  /* 
   * Stop
   */  
  PROCEDURE stop (
    p_difference_threshold IN NUMBER := 0,
    p_stat_name IN VARCHAR2 := NULL
  )
  IS
    l_run1_val NUMBER;
    l_run2_val NUMBER;
    l_run1_latch NUMBER := 0;
    l_run2_latch NUMBER := 0;
    l_diff NUMBER;
    l_pct1 VARCHAR2(50);
    l_pct2 VARCHAR2(50);
    
  BEGIN
    -- Calculate the run 2 time
    g_run2_time := (dbms_utility.get_time - g_start_time);
    
    -- Get current stats
    OPEN stats;
    FETCH stats BULK COLLECT INTO g_after2_name, g_after2_value;
    CLOSE stats;
    
    IF (g_run2_time = 0)
    THEN
      l_pct1 := '(% is NaN)';
    ELSE
      l_pct1 := '(' || ROUND( ( g_run1_time / g_run2_time ) * 100, 2 ) || '%)';
    END IF;
    
    IF (g_run1_time = 0)
    THEN
      l_pct2 := '(% is NaN)';
    ELSE
      l_pct2 := '(' || ROUND( ( g_run2_time / g_run1_time ) * 100, 2 ) || '%)';
    END IF;
    
    -- Output run times
    pl('Run1 (' || g_run1_label || ') ran in ' || g_run1_time || ' hsecs '|| l_pct1);
    pl('Run2 (' || g_run2_label || ') ran in ' || g_run2_time || ' hsecs '|| l_pct2);
    pl;

    -- Output stats that changed by more than the specified difference threshold
    -- or those requesed by p_stat_name
    pl(RPAD('Name', 50) || LPAD('Run1', 10) || LPAD('Run2', 10) || LPAD('Diff', 10) || '  Pct''s');
    
    FOR i IN g_baseline_name.FIRST .. g_baseline_name.LAST
    LOOP
      IF (g_baseline_name(i) <> g_after1_name(i) OR 
           g_baseline_name(i) <> g_after2_name(i))
      THEN
        -- this should never happen
        RAISE_APPLICATION_ERROR(-20001, 'fail. name mismatch');
      END IF;
      
      l_run1_val := g_after1_value(i) - g_baseline_value(i);
      l_run2_val := g_after2_value(i) - g_after1_value(i);
      
      l_diff := ABS(l_run1_val - l_run2_val);
      
      IF (g_baseline_name(i) LIKE 'LATCH%')
      THEN
        l_run1_latch := l_run1_latch + l_run1_val;
        l_run2_latch := l_run2_latch + l_run2_val;
      END IF;
      
      IF (l_diff >= p_difference_threshold OR
           INSTR(LOWER(g_baseline_name(i)), LOWER(p_stat_name)) > 0)
      THEN
        IF (l_run2_val = 0 AND l_run1_val = 0)
        THEN
          l_pct1 := 'NaN';
          l_pct2 := 'NaN';
        ELSIF (l_run2_val = 0)
        THEN
          l_pct1 := 'NaN';
          l_pct2 := 0;
        ELSIF (l_run1_val = 0)
        THEN
          l_pct2 := 'NaN';
          l_pct1 := 0;
        ELSE
          l_pct1 := ROUND((l_run1_val / l_run2_val) * 100, 2);
          l_pct2 := ROUND((l_run2_val / l_run1_val) * 100, 2);
        END IF;
        
        pl(RPAD(g_baseline_name(i), 50) ||
            TO_CHAR(l_run1_val, '9,999,999') ||
            TO_CHAR(l_run2_val, '9,999,999') ||
            TO_CHAR(l_diff, '9,999,999') || '  ' ||
            l_pct1 || '% / ' ||
            l_pct2 || '%');
      END IF;
      
    END LOOP;
    
    pl;

    -- Output cumulative latch values
    pl('Total latches :' || eol);
    pl(LPAD('Run1', 10) || LPAD('Run2', 10) || LPAD('Diff', 10) || '  Pct''s');
    
    pl(TO_CHAR(l_run1_latch, '9,999,999') ||
        TO_CHAR(l_run2_latch, '9,999,999') ||
        TO_CHAR(ABS(l_run1_latch - l_run2_latch), '9,999,999') || '  ' ||
        ROUND((l_run1_latch / l_run2_latch) * 100, 2) || '% / ' ||
        ROUND((l_run2_latch / l_run1_latch) * 100, 2) || '%');
    
    pl;
    
    -- List sessions that could affect the latch numbers
    FOR i IN (SELECT username, count(*) AS n
                FROM v$session
               WHERE username IS NOT NULL
               GROUP BY username)
    LOOP
      pl(i.username || ' has ' || i.n || ' sessions open.');

    END LOOP; 
    
  END stop;
  
END stats;
/
