/**
  particle-physics-windchime
 */

///////////////////////////////////////////////////////////////////////////////
// GUI stuff
///////////////////////////////////////////////////////////////////////////////
import controlP5.*;

ControlP5 controlP5;

DropdownList p1, p2;
DropdownList[] dd_sonic;
///////////////////////////////////////////////////////////////////////////////
import javax.swing.JFileChooser;
///////////////////////////////////////////////////////////////////////////////
import arb.soundcipher.*;
///////////////////////////////////////////////////////////////////////////////
import processing.opengl.*;
///////////////////////////////////////////////////////////////////////////////
// PeasyCam - a good camera.
import peasy.*;
///////////////////////////////////////////////////////////////////////////////


SoundCipher sc = new SoundCipher(this);
SCScore score;
float channel = 0;
float controller = 81;

String[] lines;
int index = 0;

int event_count = 0;

float instruments[] = {SCScore.PIANO, SCScore.ACOUSTIC_GUITAR, SCScore.CELLO, SCScore.TIMPANI, SCScore.SAXOPHONE, SCScore.FRENCH_HORN, SCScore.DOUBLE_BASS, SCScore.OCARINA};

String[] sonic_labels = {"Pitch", "Duration", "Volume", "Instrument"};

int musical_scale_range = 100;
float volume_range = 100;
float note_time_range = 60.0;
float duration_range = 10.0;
float pitch_range = 127;
float pan_range = 127;

int sound_mapping = 0;

// Data file
// 0 - track number
// 1 - PID
// 2 - Charge
// 3-6 - E,px,py,pz
// 7 - Detector number
// 8 - Detector time
// 9-11 - Detector x,y,z
// 12-14 - Detector r, costheta, phi

// Set ranges on things so we can normalize them.
int nranges = 15;
float[] val_lo = new float[nranges];
float[] val_hi = new float[nranges];
String[] val_name = new String[nranges];

// Hash for the particle values.
HashMap pvals = new HashMap();

int screen_width = 800;
int screen_height = 800;
int screen_depth = 800;

int xcenter = screen_width/2;
int ycenter = screen_height/2;

int background_color = 0;
int tempo = 240;

float xpos;
float ypos;
float zpos;

int num_times = 0;

float[] time_steps = new float[127];
float[][] xpositions = new float[127][500];
float[][] ypositions = new float[127][500];
float[][] zpositions = new float[127][500];
float[][] sizes = new float[127][500];

float[][] positions = new float[1000][3];
float[][] colors = new float[1000][3];

int num_sound_events = 0;

int nitems = 0;

///////////////////////////////////////////////////////////////////////////////
String[] filenames = new String[0];
String infile;

boolean process_file = false;
boolean draw_background = true;
boolean selected_a_file = false;

PeasyCam cam;
PMatrix3D currCameraMatrix;
PGraphics3D g3;

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
    size(screen_width,screen_height,P3D);
    //size(screen_width,screen_height,OPENGL);
    g3 = (PGraphics3D)g;
    cam = new PeasyCam(this, xcenter, ycenter, -screen_depth, 2.0*screen_depth);
    //cam = new PeasyCam(this, 100);
    cam.setMinimumDistance(50);
    cam.setMaximumDistance(10*screen_depth);

    background(background_color);
    //frameRate(1);
    frameRate(30);
    noStroke();
    //smooth();
    hint(ENABLE_NATIVE_FONTS);

    // Hash table
    pvals.put("tracknum",new MyInt(0));
    pvals.put("pid", new MyInt(1));
    pvals.put("q", new MyInt(2));
    pvals.put("E", new MyInt(3));
    pvals.put("px", new MyInt(4));
    pvals.put("py", new MyInt(5));
    pvals.put("pz", new MyInt(6));
    pvals.put("dnum", new MyInt(7));
    pvals.put("dtime", new MyInt(8));
    pvals.put("dx", new MyInt(9));
    pvals.put("dy", new MyInt(10));
    pvals.put("dz", new MyInt(11));
    pvals.put("dr", new MyInt(12));
    pvals.put("dcostheta", new MyInt(13));
    pvals.put("dphi", new MyInt(14));

    // Names of values
    val_name[0] = "Track #";
    val_name[1] = "PID";
    val_name[2] = "Charge";
    val_name[3] = "E";
    val_name[4] = "px";
    val_name[5] = "py";
    val_name[6] = "pz";
    val_name[7] = "Detector number";
    val_name[8] = "Detector time";
    val_name[9] = "Detector x";
    val_name[10] = "Detector y";
    val_name[11] = "Detector z";
    val_name[12] = "Detector r";
    val_name[13] = "Detector cos(theta)";
    val_name[14] = "Detector phi";

    // Ranges for values to read in from data file.
    val_lo[0] = 0.0; val_hi[0] = 30.0; // Track number (this might have to be made bigger for other experiments.
    val_lo[1] = 0.0; val_hi[1] = 5.0; // PID, photon,electron,muon,pion,kaon,proton
    val_lo[2] = -1.0; val_hi[2] = 1.0; // Charge
    val_lo[3] = 0.0; val_hi[3] = 1.5; // Energy
    val_lo[4] = -2.5; val_hi[4] = 2.5; // px
    val_lo[5] = -2.5; val_hi[5] = 2.5; // py
    val_lo[6] = -2.5; val_hi[6] = 2.5; // pz
    val_lo[7] = 0.0; val_hi[7] = 1.0; // Detector number
    val_lo[8] = 0.0; val_hi[8] = 30.0; // Detector time
    val_lo[9] = -2.5; val_hi[9] =  2.5; // x range
    val_lo[10] = -2.5; val_hi[10] =  2.5; // y range
    val_lo[11] = -2.5; val_hi[11] =  2.5; // z range
    val_lo[12] = 0.0; val_hi[12] = 3.0; // radius range
    val_lo[13] = -1.0; val_hi[13] =  1.0; // costheta range
    val_lo[14] = -1.0; val_hi[14] =  1.0; // phi range

    ////////////////////////////////////////////////////////////////////
    // Set up the score.
    ////////////////////////////////////////////////////////////////////
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
    p1 = controlP5.addDropdownList("myList-p1",240,45,120,120);
    customize_filelist(p1);
    p2 = controlP5.addDropdownList("myList-p2",500,45,120,120);
    customize_mapping(p2);
    //dd_sonic_0 = controlP5.addDropdownList("dd_sonic_0",10,100,80,80);
    //customize_dd_sonic(dd_sonic_0,0);
    dd_sonic = new DropdownList[4];
    for (int i=0;i<4;i++)
    {
        String name = "dd_sonic_" + i;
        dd_sonic[i] = controlP5.addDropdownList(name,10,80+20*i,80,80);
        customize_dd_sonic(dd_sonic[i],i);
    }

    controlP5.addButton("Play",0,10,30,50,19);
    controlP5.addButton("Stop",0,80,30,50,19);
    controlP5.addButton("Pause",0,150,30,50,19);

    controlP5.addSlider("Tempo",0,480,240,20,screen_height-140,10,100);

    background(0);
    controlP5.setAutoDraw(false);

    hint(ENABLE_NATIVE_FONTS);



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

    background(0);
    //lights();

    // Set up some different colored lights
    pointLight(51, 102, 255, 65, 60, 100);
    //pointLight(200, 40, 60, -65, -60, -150);
    // Raise overall light in scene
    //ambientLight(70, 70, 10);

    //lights();

    //directionalLight(126, 126, 126, 0, 0, -1);
    ambientLight(102, 102, 102);

    for (int i=0;i<nitems;i++)
    {
        //fill(255,255,0);
        fill(colors[i][0],colors[i][1],colors[i][2]);
        pushMatrix();
        translate(positions[i][0],positions[i][1],positions[i][2]);
        //sphere(5);
        box(5);
        popMatrix();
    }
    //controlP5.draw();
    hint(DISABLE_DEPTH_TEST);
    gui();

}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void gui() {
    currCameraMatrix = new PMatrix3D(g3.camera);
    camera();

    // Might need the lights here so we can see the controlP5 gui
    noLights();
    controlP5.draw();

    g3.camera = currCameraMatrix;
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void makeMusic() 
{
    fill(255,255,0);
    if (process_file)
    {
        background(0);
        lights();

        float pitch = 0.0;
        float volume = 0.0;
        int channel = 0;
        double instrument = 0.0;
        double articulation = 0.0; // 0.2 is stacatto, 1.0 is legato
        double pan = 64.0;
        double duration = 0.0;

        process_file = false;
        println("Just inside of process_file");
        score.empty();

        String line = "DEFAULTLINE";
        try{
            line = reader.readLine();
            println(line);
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
                zpositions[i][j] = 0.0;
                sizes[i][j] = 0.0;
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
                float[] norm_vals = new float[nranges];

                for (int j=0;j<nranges;j++)
                {
                    norm_vals[j] = (float(vals[j]) - val_lo[j])/(val_hi[j] - val_lo[j]);
                }

                // Normalize the energy
                MyInt ii = (MyInt)pvals.get("E");
                //println("energy: " + (int)ii.getVal() + " " + norm_vals[((MyInt)pvals.get("E")).getVal()]);
                ///*
                float energy = norm_vals[((MyInt)pvals.get("E")).getVal()];
                float time = norm_vals[((MyInt)pvals.get("dtime")).getVal()];
                float radius = norm_vals[((MyInt)pvals.get("dr")).getVal()];
                float costheta = norm_vals[((MyInt)pvals.get("dcostheta")).getVal()];
                float x = norm_vals[((MyInt)pvals.get("dx")).getVal()];
                float y = norm_vals[((MyInt)pvals.get("dy")).getVal()];
                float z = norm_vals[((MyInt)pvals.get("dz")).getVal()];
                int detector = int(norm_vals[((MyInt)pvals.get("dnum")).getVal()]);
                int pid = int(norm_vals[((MyInt)pvals.get("pid")).getVal()]);
                float px = norm_vals[((MyInt)pvals.get("px")).getVal()];
                float py = norm_vals[((MyInt)pvals.get("py")).getVal()];
                float pz = norm_vals[((MyInt)pvals.get("pz")).getVal()];
                float pmag = sqrt(px*px + py*py + pz*pz);
                //*/

                xpos = screen_width*x;
                ypos = screen_height*y;
                zpos = screen_depth*z;

                ////////////////////////////////////////////////////////////////////
                // Map onto the sonic characteristics.
                ////////////////////////////////////////////////////////////////////
                if (sound_mapping==0)
                {
                    pitch = pitch_range*(radius/2.0) + z*40 + 20;
                    if (pitch>126) pitch = 126;
                }
                else if (sound_mapping==1)
                {
                    pitch = pitch_range*(costheta);
                }
                else if (sound_mapping==2)
                {
                    pitch = pitch_range*(costheta/4.0) + 40;
                }
                else if (sound_mapping==3)
                {
                    pitch = pitch_range*energy;
                    //println("pitch: " + pitch + " " + pitch_range + " " + energy);
                }
                else if (sound_mapping==4)
                {
                    pitch = pitch_range*pmag;
                    println("pitch: " + pitch + " " + pitch_range + " " + pmag);
                }
                else if (sound_mapping==5)
                {
                    pitch = pitch_range* (1.0 - exp(-0.7*pmag));
                    println("pitch: " + pitch + " " + pitch_range + " " + pmag);
                }

                volume = volume_range*energy;
                //println("volume: " + volume);
                note_time = note_time_range*time;
                if (max_note_time<note_time)
                {
                    max_note_time = note_time;
                }
                //float volume = 30.0*radius;

                channel = 1;

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

                articulation = 1.0;

                pan = pan_range*z;
                if (pan<0) pan=0;
                if (pan>127) pan=127;

                duration = 5.0;

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
                        zpositions[j][npos] = zpos;
                        sizes[j][npos] = detector;
                        xpositions[j][0]++;
                        ypositions[j][0]++;
                        zpositions[j][0]++;
                        sizes[j][0]++;
                        found_time = true;
                    }
                }
                if (!found_time)
                {
                    //println("Adding " + note_time + "\tnum_times: " + num_times);
                    time_steps[num_times] = note_time;
                    xpositions[num_times][1] = xpos;
                    ypositions[num_times][1] = ypos;
                    zpositions[num_times][1] = zpos;
                    sizes[num_times][1] = detector;
                    xpositions[num_times][0] = 1;
                    ypositions[num_times][0] = 1;
                    zpositions[num_times][0] = 1;
                    sizes[num_times][0] = 1;
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
                //println(note_time + " " + channel + " " + instrument + " " + pitch + " " + volume + " " + duration + " " + articulation + " " + pan);
                score.addNote(note_time, channel, instrument, pitch, volume, duration, articulation, pan);
                //int id = i+1;
                //id = id%200 + 1;
                //score.addCallback(note_time, id);
                // callbackID seems to need to be less than 127!!!! ???
                if (!found_time)
                {
                    score.addCallback(note_time, callbackID);
                    //println("callbackID: " + callbackID + " " + note_time);
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
        note_time=max_note_time + 10;
        //println("ELSE note_time: " + note_time);
        score.addCallback(note_time, 0);

        println("Playing something!!!!!!!!!! --------------------- ");

        draw_background = false;
        process_file = false;
        //background(0);
        //String outname = "BpBm_events_mapping" + sound_mapping + "/event_" + event_count + ".mid";
        //String outname = "tauptaum_events_mapping" + sound_mapping + "/event_" + event_count + ".mid";
        //println("Saving as: " + outname);
        //score.writeMidiFile(outname);

        score.play();

        println("PLAYING!");
        event_count++;


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

            nitems = 0;
            score.stop();
            nitems = 0;
            background(background_color);
            println("About to makeMusic from case 0");

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
                positions[nitems][0] = xpositions[time_index][j];
                positions[nitems][1] = ypositions[time_index][j];
                positions[nitems][2] = zpositions[time_index][j];
                float t = time_steps[time_index];

                if (sizes[time_index][j]<20) 
                { 
                    colors[nitems][0] = 155;
                    colors[nitems][1] = 210;
                    colors[nitems][2] = 255;
                }
                else if (sizes[time_index][j]>=20) 
                { 

                    colors[nitems][0] = 255;
                    colors[nitems][1] = 255;
                    colors[nitems][2] = 0;
                }
                nitems++;
            }
            //println("time_index/nitems: " + time_index + " " + nitems);
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
    ddl.setHeight(300);
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
void customize_mapping(DropdownList ddl) {
    ddl.setItemHeight(15);
    ddl.setBarHeight(15);
    ddl.setWidth(120);
    ddl.captionLabel().set("Choose a mapping");
    ddl.captionLabel().style().marginTop = 3;
    ddl.valueLabel().style().marginTop = 3;
    // Make some drop down items
    int num_mappings = 6;
    for(int i=0;i<num_mappings;i++) {
        String name = "Mapping " + i;
        ddl.addItem(name,i);
    }
    ddl.setColorActive(color(0,0,255,128));
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void customize_dd_sonic(DropdownList ddl, int index) {
    ddl.setItemHeight(15);
    ddl.setHeight(400);
    ddl.setBarHeight(15);
    ddl.setWidth(120);
    ddl.captionLabel().set(sonic_labels[index] + ": ");
    ddl.captionLabel().style().marginTop = 3;
    ddl.valueLabel().style().marginTop = 3;
    // Make some drop down items
    for(int i=0;i<nranges;i++) {
        String name = val_name[i];
        ddl.addItem(name,i);
    }
    ddl.setColorActive(color(0,0,255,128));
    ddl.setColorBackground(color(255,0,255,128));
}
///////////////////////////////////////////////////////////////////////////////
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
        process_file = true;
    }
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
public void Stop(int theValue) {
    println("a button event from Stop: "+theValue);
    //myColor = theValue;

    nitems=0;
    score.stop();
    draw_background = true;
    process_file = false;
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
public void Pause(int theValue) {
    println("a button event from Pause: "+theValue);
    //myColor = theValue;

    nitems=0;
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
    String event_name = theEvent.name();

    if (theEvent.isGroup()) {
        // check if the Event was triggered from a ControlGroup
        //println(theEvent.group().value()+" from "+theEvent.group());
        //println("CLICKED");
        //println(theEvent.group());
        //println(event_name);
    } else if(theEvent.isController()) {
        //println(theEvent.controller().value()+" from "+theEvent.controller());
        //println(theEvent.controller().value()+" from "+theEvent.group());
    }

    if (event_name == "myList-p1")
    {
        int index = int(theEvent.group().value());
        infile = filenames[index];
        reader = createReader(infile);
        //process_file = true;
        selected_a_file = true;
        event_count = 0;
    }
    else if (event_name == "myList-p2")
    {
        int index = int(theEvent.group().value());
        sound_mapping = index;
    }
    // Process the events from the dd_sonic_X dropdown menus.
    else if (event_name.charAt(0)=='d' && event_name.charAt(1)=='d' &&
            event_name.charAt(3)=='s')
    {
        int dd_index = 0;
        char tc = event_name.charAt(9);
        if (tc=='0') dd_index=0;
        else if (tc=='1') dd_index=1;
        else if (tc=='2') dd_index=2;
        else if (tc=='3') dd_index=3;

        println("dd_index: " + dd_index + " " + event_name.charAt(9));
        int index = int(theEvent.group().value());
        String name = sonic_labels[dd_index] + ": " + val_name[index];
        dd_sonic[dd_index].captionLabel().set(name);
        event_count = 0;
    }

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

class MyInt {

    int val;

    MyInt(int i)
    {
        val = i;
    }

    void setVal(int i)
    {
        val = i;
    }

    int getVal()
    {
        return val;
    }
}
