/**
 */

///////////////////////////////////////////////////////////////////////////////
// GUI stuff
///////////////////////////////////////////////////////////////////////////////
import controlP5.*;

ControlP5 controlP5;

DropdownList p1, p2;
///////////////////////////////////////////////////////////////////////////////
import javax.swing.JFileChooser;
///////////////////////////////////////////////////////////////////////////////
import arb.soundcipher.*;
///////////////////////////////////////////////////////////////////////////////

SoundCipher sc = new SoundCipher(this);
SCScore score;
float channel = 0;
float controller = 81;

String[] lines;
int index = 0;

float instruments[] = {SCScore.PIANO, SCScore.ACOUSTIC_GUITAR, SCScore.CELLO, SCScore.TIMPANI, SCScore.SAXOPHONE, SCScore.FRENCH_HORN, SCScore.DOUBLE_BASS, SCScore.OCARINA};

int musical_scale_range = 100;
float volume_range = 100;
float note_time_range = 60.0;
float duration_range = 10.0;
float pitch_range = 127;
float pan_range = 127;

// Set ranges on things so we can normalize them.
// energy
// radius
// time
// costheta
// z
int nranges = 7;
float[] val_lo = new float[nranges];
float[] val_hi = new float[nranges];

int screen_width = 800;
int screen_height = 800;

int background_color = 0;
int tempo = 240;

float xpos;
float ypos;

int num_times = 0;

float[] time_steps = new float[127];
float[][] xpositions = new float[127][500];
float[][] ypositions = new float[127][500];

int num_sound_events = 0;

///////////////////////////////////////////////////////////////////////////////
String[] filenames = new String[0];
String infile;

boolean process_file = false;
boolean draw_background = true;
boolean selected_a_file = false;

///////////////////////////////////////////////////////////////////////////////
BufferedReader reader;
JFileChooser chooser = new JFileChooser();
///////////////////////////////////////////////////////////////////////////////
// Grabbed this from http://wiki.processing.org/w/BufferedReader
///////////////////////////////////////////////////////////////////////////////
public BufferedReader createReader(String filename) {
    try {
        InputStream is = openStream(filename);
        if (is == null) {
            System.err.println(filename + " does not exist or could not be read");
            return null;
        }
        return createReader(is);
    } catch (Exception e) {
        if (filename == null) {
            System.err.println("Filename passed to reader() was null");
        } else {
            System.err.println("Couldn't create a reader for " + filename);
        }
    }
    return null;
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void setup()
{
    size(screen_width,screen_height);
    background(background_color);
    //frameRate(1);
    frameRate(10);
    smooth();

    // Energy range
    val_lo[0] = 0.0; val_hi[0] = 1.2;
    // radius range
    val_lo[1] = 0.0; val_hi[1] = 3.0;
    // Time range
    val_lo[2] = 0.0; val_hi[2] = 30.0;
    // costheta range
    val_lo[3] = -1.0; val_hi[3] =  1.0;
    // x range
    val_lo[4] = -2.5; val_hi[4] =  2.5;
    // y range
    val_lo[5] = -2.5; val_hi[5] =  2.5;
    // z range
    val_lo[6] = -2.5; val_hi[6] =  2.5;

    ////////////////////////////////////////////////////////////////////
    // Read in a file
    ////////////////////////////////////////////////////////////////////
    //lines = loadStrings("events_1237_10.txt");
    //lines = loadStrings("events_3429_10.txt");
    //lines = loadStrings("events_mupmum_CM_10.txt");
    //lines = loadStrings("events_bbbar_CM_1.txt");
    //lines = loadStrings("events_3429_1.txt");


    score = new SCScore();
    score.addCallbackListener(this);
    score.tempo(tempo);

    // Path
    String path = dataPath("");
    println("Listing all filenames in a directory: ");
    //println(path);
    String[] temp_filenames = listFileNames(path);
    int nfiles = temp_filenames.length;
    //println(temp_filenames);
    int j = 0;
    for (int i=0;i<nfiles;i++)
    {
        if (temp_filenames[i].endsWith("txt"))
        {
            //println(temp_filenames[i]);
            filenames = append(filenames, temp_filenames[i]);
            j++;
        }
    }
    //println(filenames);

    controlP5 = new ControlP5(this);
    controlP5.setAutoDraw(false);
    p1 = controlP5.addDropdownList("myList-p1",screen_width-300,80,120,120);
    customize_filelist(p1);

    controlP5.addButton("Play",0,10, 60,50,19);
    controlP5.addButton("Stop",0,100,60,50,19);

    controlP5.addSlider("Tempo",0,480,120,20,100,10,100);

    //makeMusic();

    background(0);
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void draw() {
    score.tempo(tempo);
    if (process_file)
    {
        makeMusic();
    }
    if (draw_background)
    {
        background(0);
    }
    controlP5.draw();
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void makeMusic() 
{
    //fill(255,193,193,50);
    fill(255,193,193);
    if (process_file)
    {
        process_file = false;
        println("Just inside of process_file");
        score.empty();

        String line = "DEFAULTLINE";
        try{
            line = reader.readLine();
            num_sound_events = int(line);
            println("num_sound_events: " + num_sound_events);
        }
        catch (Exception e)
        {
            e.printStackTrace();
            exit();
        }


        ///////////////////////////////////////////////////////////////////////////
        // Zero out the arrays
        ///////////////////////////////////////////////////////////////////////////
        for (int i=0;i<127;i++)
        {
            time_steps[i] = 0.0;
            for (int j=0;j<500;j++)
            {
                xpositions[i][j] = 0.0;
                ypositions[i][j] = 0.0;
            }
        }
        ///////////////////////////////////////////////////////////////////////////

        float prev_time = 0.0;
        float now_time = 0.0;

        float note_time = 0.0;
        float max_note_time = -1.0;

        num_times = 0;

        int count = 0;


        //int nentries = int(vals[0]);
        //println("nentries: " + nentries);

        //int max = nentries;
        //max = 125;
        //max = 300;
        int callbackID = 1;
        for (int i = 0; i < num_sound_events; i++) 
        {
            // Read in a line
            //String line = "DEFAULTLINE";
            try{
                line = reader.readLine();
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }

            //line = reader.readLine();
            String[] vals = split(line, ' ');
            //println(vals);

            if (vals.length>1)
            {
                float energy = float(vals[3]);
                float time = float(vals[8]);
                float radius = float(vals[12]);
                int pid = int(vals[1]);
                int detector = int(vals[7]);
                float costheta = float(vals[13]);
                float x = float(vals[9]);
                float y = float(vals[10]);
                float z = float(vals[11]);

                // Normalize the energy
                energy = ((energy-val_lo[0])/(val_hi[0]-val_lo[0]));
                //println("energy: " + energy);

                // Normalize the time
                time = ((time-val_lo[2])/(val_hi[2]-val_lo[2]));
                //println("time: " + time);

                // Normalize the radius
                radius = ((radius-val_lo[1])/(val_hi[1]-val_lo[1]));
                //println("radius: " + radius);

                // Normalize the costheta
                costheta = ((costheta-val_lo[3])/(val_hi[3]-val_lo[3]));

                // Normalize the x,y,z
                x = ((x-val_lo[4])/(val_hi[4]-val_lo[4]));
                y = ((y-val_lo[5])/(val_hi[5]-val_lo[5]));
                z = ((z-val_lo[6])/(val_hi[6]-val_lo[6]));

                xpos = screen_width*x;
                ypos = screen_height*y;

                ////////////////////////////////////////////////////////////////////
                // Map onto the sonic characteristics.
                ////////////////////////////////////////////////////////////////////
                //float pitch = pitch_range*radius + 40 + costheta*10;
                float pitch = pitch_range*(radius/2.0) + z*40 + 20;
                //float pitch = energy;

                float volume = volume_range*energy;
                //println("volume: " + volume);
                note_time = note_time_range*time;
                if (max_note_time<note_time)
                {
                    max_note_time = note_time;
                }
                //float volume = 30.0*radius;

                int channel = 1;

                double instrument = 0.0;
                if (detector>=0 && detector<20)
                {
                    instrument = instruments[0];
                    channel = 3;
                }
                else
                {
                    instrument = instruments[3];
                    channel = 4;
                }

                //note_time = int(note_time);

                //println("i detector/instrument/note_time/pitch: " + i + " " + detector + " " + instrument + " " + note_time + " " + pitch);
                //println("i note_time/pitch: " + i + " " + note_time + " " + pitch);

                //instrument = instruments[pid];
                //channel = pid+1;

                //double articulation = 0.2; // Stacatto
                double articulation = 1.0; // Legato

                //double pan = 64.0;
                //println(i);
                //double pan = 50 * (i%2);
                //double pan = pan_range*costheta;
                double pan = pan_range*z;
                //println(pan);
                //double duration = energy/20.0;
                double duration = 5.0;

                ///////////////////////////////////////////////////////////////////
                boolean found_time = false;
                for (int j=0;j<num_times;j++)
                {
                    //println("Searching --- " + time_steps[j]);
                    if (time_steps[j] == note_time)
                    {
                        //println(note_time);
                        int npos = int(xpositions[j][0]);
                        xpositions[j][npos] = xpos;
                        ypositions[j][npos] = ypos;
                        xpositions[j][0]++;
                        ypositions[j][0]++;
                        found_time = true;
                    }
                }
                if (!found_time)
                {
                    //println("Adding " + note_time + "\tnum_times: " + num_times);
                    time_steps[num_times] = note_time;
                    xpositions[num_times][1] = xpos;
                    ypositions[num_times][1] = ypos;
                    xpositions[num_times][0] = 1;
                    ypositions[num_times][0] = 1;
                    num_times++;
                    if (num_times>=127)
                    {
                        num_times=126;
                    }
                }
                ///////////////////////////////////////////////////////////////////

                //pitch += random(30);
                //pitch = 60;
                volume = 100;
                score.addNote(note_time, channel, instrument, pitch, volume, duration, articulation, pan);
                //int id = i+1;
                //id = id%200 + 1;
                //score.addCallback(note_time, id);
                // callbackID seems to need to be less than 127!!!! ???
                if (!found_time)
                {
                    score.addCallback(note_time, callbackID);
                    println("callbackID: " + callbackID + " " + note_time);
                    callbackID++;
                }
                // The integer here (callbackID) has to be less than 256!
                //score.addCallback(note_time, 1);
            }
        }

        //for (int j=0;j<num_times;j++)
        //{
            //println("time_steps/xpositions: " + time_steps[j] + " " + xpositions[j][0]);
        //}

        //note_time+=10;
        note_time=max_note_time + 2;
        //println("ELSE note_time: " + note_time);
        score.addCallback(note_time, 0);

        println("Playing something!!!!!!!!!! --------------------- ");

        draw_background = false;
        process_file = false;
        //background(0);
        score.play();
        //score.writeMidiFile("my_test.mid");

        println("PLAYING!");


        //exit();

        // Set up for a new event/score.

    }
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void stop() {
    score.stop();
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void handleCallbacks(int callbackID) {
    //println("callbackID: " + int(callbackID));
    switch (callbackID) {
        case 0:
            
            score.stop();
            background(background_color);
            println("About to makeMusic from case 0");
            // Read in a line
            /*
            String line = "DEFAULTLINE";
            try{
                line = reader.readLine();
                num_sound_events = int(line);
                println("num_sound_events: " + num_sound_events);
            }
            catch (Exception e)
            {
                e.printStackTrace();
                exit();
            }
            */

            process_file = true;
            draw_background = true;
            score.empty();
            makeMusic();
            println("Just did makeMusic from case 0");
            break;

        default:

            //draw_background = false;
            int time_index = callbackID-1;
            int npoints = int(xpositions[time_index][0]);
            for (int j=1;j<npoints+1;j++)
            {
                float x = xpositions[time_index][j];
                float y = ypositions[time_index][j];
                float t = time_steps[time_index];

                float r = sqrt(x*x+y*y);

                fill(155,10+r/3.0,93+r/3.0);
                println("In callback : "+callbackID+" "+t);
                ellipse(x, y, 5, 5);
            }

            redraw();
    }
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////
void customize_filelist(DropdownList ddl) {
    //ddl.setBackgroundColor(color(190));
    ddl.setItemHeight(15);
    ddl.setBarHeight(15);
    //ddl.setHeight(300);
    ddl.setWidth(200);
    ddl.captionLabel().set("Choose a file");
    ddl.captionLabel().style().marginTop = 3;
    ddl.valueLabel().style().marginTop = 3;
    // Make some drop down items
    int nfiles = filenames.length;
    for(int i=0;i<nfiles;i++) {
        ddl.addItem(filenames[i],i);
    }
    //ddl.setColorBackground(color(255,128));
    //ddl.setColorForeground(color(255));
    //ddl.setColorLabel(color(0));
    ddl.setColorActive(color(0,0,255,128));
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// function buttonA will receive changes from 
// controller with name buttonA
///////////////////////////////////////////////////////////////////////////////
public void Play(int theValue) {
    println("a button event from Play: "+theValue);
    //myColor = theValue;

    if (selected_a_file)
    {
        background(0);
        redraw();

        // Read in a line
        /*
        String line = "DEFAULTLINE";
        try{
            line = reader.readLine();
            //println(line);
            num_sound_events = int(line);
            println("num_sound_events: " + num_sound_events);
        }
        catch (Exception e)
        {
            e.printStackTrace();
            exit();
        }
        */

        process_file = true;
    }
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
public void Stop(int theValue) {
    println("a button event from Stop: "+theValue);
    //myColor = theValue;

    score.stop();
    //draw_background = true;
    process_file = false;
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////



void controlEvent(ControlEvent theEvent) 
{
    // PulldownMenu is if type ControlGroup.
    // A controlEvent will be triggered from within the ControlGroup.
    // therefore you need to check the originator of the Event with
    // if (theEvent.isGroup())
    // to avoid an error message from controlP5.

    if (theEvent.isGroup()) {
        // check if the Event was triggered from a ControlGroup
        println(theEvent.group().value()+" from "+theEvent.group());
        println("CLICKED");
        println(theEvent.group());
        println(theEvent.name());
    } else if(theEvent.isController()) {
        println(theEvent.controller().value()+" from "+theEvent.controller());
    }

    if (theEvent.name() == "myList-p1")
    {
        int index = int(theEvent.group().value());
        infile = filenames[index];
        reader = createReader(infile);
        //process_file = true;
        selected_a_file = true;


        //score.stop();
        //lines = loadStrings(infile);
    }
    //makeMusic();
}

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// This function returns all the files in a directory as an array of Strings
///////////////////////////////////////////////////////////////////////////////
String[] listFileNames(String dir) {
    File file = new File(dir);
    if (file.isDirectory()) {
        String names[] = file.list();
        return names;
    } else {
        // If it's not a directory
        return null;
    }
}
///////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
private String[][] bubbleSortMulti(String[][] MultiIn, int compIdx) {  
    String[][] temp = new String[MultiIn.length][MultiIn[0].length];  
    boolean finished = false;  
    while (!finished) {  
        finished = true;  
        for (int i = 0; i < MultiIn.length - 1; i++) {  
            if (MultiIn[i][compIdx].compareToIgnoreCase(MultiIn[i + 1][compIdx]) > 0) {  
                for (int j = 0; j < MultiIn[i].length; j++) {  
                    temp[i][j] = MultiIn[i][j];  
                    MultiIn[i][j] = MultiIn[i + 1][j];  
                    MultiIn[i + 1][j] = temp[i][j];  
                }  
                finished = false;  
            }  
        }  
    }  
    return MultiIn;  
}  
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
void Tempo(float value) {
      tempo = int(value);
      println("a slider event. setting background to "+tempo);
}
///////////////////////////////////////////////////////////////////////////////
