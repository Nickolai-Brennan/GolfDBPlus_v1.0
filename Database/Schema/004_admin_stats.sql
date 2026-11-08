create TABLE IF NOT EXISTS Data_Totals (
    total_id serial PRIMARY KEY,
    total_name text NOT NULL,
    total_value numeric NOT NULL,
    
    filter_type text NOT NULL,
         time_period text NOT NULL,
         data_category text NOT NULL,
         collection text NOT NULL CHECK (collection IN ('Counting Stats', 'Scores', 'Rankings', 'Analytics Measurments', 'Statistics', 'Miscellaneous')),
         data_types text NOT NULL CHECK (data_types IN ('Shot Data', 'Stat Tracking', 'Financial', 'Strokes Gained', 'Miscellaneous', 'Course Data', 'Hole Data', 'Event Data', 'Player Data'))
        

);

