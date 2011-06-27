/**
  particle-physics-windchime
 */

int num_physics = 7;
String[] physics_processes = new String[num_physics];

///////////////////////////////////////////////////////////////////////////////
// GUI stuff
///////////////////////////////////////////////////////////////////////////////
import controlP5.*;

ControlP5 controlP5;

DropdownList p1, p2;
MultiList cp5_multilist_files;
MultiList cp5_multilist_mapping;

Matrix cp5_matrix_sonic;
int[] sonic_index = new int[4];
int sonic_map_index = -1;

Button cp5_button_play;
Button cp5_button_stop;
Button cp5_button_pause;

Textlabel cp5_tl_map_status; 
Textlabel[] cp5_tl_sonic_x = new Textlabel[20];
Textlabel[] cp5_tl_sonic_y = new Textlabel[20];

Button[] cp5_b_pick_physics = new Button[num_physics];
int button_color_on = 120;
int button_color_off = color(255,120,100);
int mapping_button_color_off = color(60,179,113);

int num_mapping = 4;
Button[] cp5_b_pick_mapping = new Button[num_physics];

RadioButton cp5_rb_pick_physics;

DropdownList[] dd_sonic;
CheckBox checkbox;
Toggle cp5_toggle_mute;
Toggle cp5_toggle_blind;

ControlWindow controlWindow;

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

int sound_mapping = -1;
int event_time = 0;

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

int matrix_sonic_nx = sonic_labels.length;
int matrix_sonic_ny = val_name.length;

// Hash for the particle values.
HashMap pvals = new HashMap();

int screen_width = 800;
int screen_height = 800;
int screen_depth = 800;

int xcenter = screen_width/2;
int ycenter = screen_height/2;
int zcenter = screen_depth/2;

float xcenter_f = float(xcenter);
float ycenter_f = float(ycenter);
float zcenter_f = float(zcenter);

int background_color = 0;
int tempo = 60;

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
float[] detector_flag = new float[1000];

int num_sound_events = 0;

int nitems = 0;

///////////////////////////////////////////////////////////////////////////////
// For the beam
float[][] beam_x = new float[2][10];
float[][] beam_y = new float[2][10];
float[][] beam_z = new float[2][10];
float[][] beam_z_offset = new float[2][10];
float beam_size = 40;
float beam_size_half = beam_size/2.0;
boolean collision_occurred = false;
///////////////////////////////////////////////////////////////////////////////
String mapping_button_label = "Choose a mapping";
String[] mapping = new String[0];
String[] filenames = new String[0];
String[] pick_filenames = new String[0];
String infile;

boolean process_file = false;
boolean draw_background = true;
boolean selected_a_file = false;
boolean set_volume_to_0 = false;
boolean dont_show_graphics = false;

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
    cam = new PeasyCam(this, xcenter, ycenter, zcenter, 1.2*screen_depth);
    //cam = new PeasyCam(this, 100);
    //cam.setMinimumDistance(50);
    //cam.setMaximumDistance(10*screen_depth);

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
    val_lo[0] = 0.0; val_hi[0] = 1.0; // Track number (this might have to be made bigger for other experiments.
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
    // Physics processes
    ////////////////////////////////////////////////////////////////////
    physics_processes[0] = "e+e-";
    physics_processes[1] = "mu+mu-";
    physics_processes[2] = "tau+tau-";
    physics_processes[3] = "uds";
    physics_processes[4] = "ccbar";
    physics_processes[5] = "B+B-";
    physics_processes[6] = "B0B0bar";

    pick_filenames = append(pick_filenames, "events_e+e-_100.txt");
    pick_filenames = append(pick_filenames, "events_mu+mu-_100.txt");
    pick_filenames = append(pick_filenames, "events_tau+tau-_100.txt");
    pick_filenames = append(pick_filenames, "events_uubar_ddbar_ssbar_100.txt");
    pick_filenames = append(pick_filenames, "events_ccbar_100.txt");
    pick_filenames = append(pick_filenames, "events_B+B-_100.txt");
    pick_filenames = append(pick_filenames, "events_B0B0bar_100.txt");
    int len_pf = (pick_filenames.length);
    println("pf len: " + len_pf);


    ////////////////////////////////////////////////////////////////////
    // Set up the score.
    ////////////////////////////////////////////////////////////////////
    score = new SCScore();
    score.addCallbackListener(this);
    score.tempo(tempo);

    ///////////////////////////////////////////////////////////////////////////
    // Path
    ///////////////////////////////////////////////////////////////////////////
    String path = dataPath("");
    println("Listing all filenames in a directory: ");
    //println(path);
    String[] temp_filenames = listFileNames(path);
    int nfiles = temp_filenames.length;
    //println(temp_filenames);
    //int j = 0;
    for (int i=0;i<nfiles;i++)
    {
        if (temp_filenames[i].endsWith("txt"))
        {
            //println(temp_filenames[i]);
            filenames = append(filenames, temp_filenames[i]);
            //j++;
        }
    }
    //println(filenames);

    // Initialize the beam positions
    for (int j=0;j<2;j++)
    {
        for (int i=0;i<10;i++)
        {
            beam_x[j][i] = random(beam_size) - beam_size_half + xcenter_f;
            beam_y[j][i] = random(beam_size) - beam_size_half + ycenter_f;
            beam_z_offset[j][i] = random(beam_size) - beam_size_half;
        }
    }

    sonic_index[0] = -1;
    sonic_index[1] = -1;
    sonic_index[2] = -1;
    sonic_index[3] = -1;

    ///////////////////////////////////////////////////////////////////////////
    // Draw all the GUI stuff. 
    ///////////////////////////////////////////////////////////////////////////
    controlP5 = new ControlP5(this);
    controlP5.setAutoDraw(false);

    controlWindow = controlP5.addControlWindow("controlP5window",100,100,600,600);
    controlWindow.hideCoordinates();
    controlWindow.setBackground(color(40));
    controlWindow.frameRate(15);

    //p1 = controlP5.addDropdownList("myList-p1",240,45,120,120);
    //customize_filelist(p1);
    //p2 = controlP5.addDropdownList("myList-p2",500,45,120,120);
    // Clear out the preset mappings
    //customize_mapping(p2);

    //cp5_multilist_mapping = controlP5.addMultiList("cp5_multilist_mapping",300,350,140,20);
    //cp5_multilist_mapping.setWindow(controlWindow);
    //customize_multilist_mapping(cp5_multilist_mapping);

    //cp5_tl_map_status = controlP5.addTextlabel("tl_map_status",mapping_button_label,300,380);
    //cp5_tl_map_status.setWindow(controlWindow);

    //cp5_multilist_files = controlP5.addMultiList("cp5_multilist_files",240,45,200,20);
    //cp5_multilist_files.setWindow(controlWindow);
    //customize_multilist_files(cp5_multilist_files);

    //cp5_rb_pick_physics = controlP5.addRadioButton("radioButton",20,160);
    //cp5_rb_pick_physics.setColorForeground(color(120));
    //cp5_rb_pick_physics.setColorActive(color(255));
    //cp5_rb_pick_physics.setColorLabel(color(255));
    //cp5_rb_pick_physics.setItemsPerRow(5);
    //cp5_rb_pick_physics.setSpacingColumn(50);
    //customize_rb_pick_physics(cp5_rb_pick_physics);

    for (int i=0;i<7;i++)
    {
        cp5_b_pick_physics[i] = controlP5.addButton("pick_"+physics_processes[i],i,70,100+(20*i),80,19);
        cp5_b_pick_physics[i].setLabel(physics_processes[i]);
        cp5_b_pick_physics[i].setColorBackground(color(button_color_off));
        cp5_b_pick_physics[i].setColorForeground(color(120));
        cp5_b_pick_physics[i].setColorActive(color(0));
        cp5_b_pick_physics[i].setColorLabel(color(255));
        cp5_b_pick_physics[i].setId(i);
        cp5_b_pick_physics[i].setWindow(controlWindow);
    }

    for (int i=0;i<num_mapping;i++)
    {
        cp5_b_pick_mapping[i] = controlP5.addButton("mapping_pick_"+i,i,170,100+(20*i),80,19);
        cp5_b_pick_mapping[i].setLabel("Mapping "+i);
        cp5_b_pick_mapping[i].setColorBackground(color(mapping_button_color_off));
        cp5_b_pick_mapping[i].setColorForeground(color(120));
        cp5_b_pick_mapping[i].setColorActive(color(0));
        cp5_b_pick_mapping[i].setColorLabel(color(255));
        cp5_b_pick_mapping[i].setId(i);
        cp5_b_pick_mapping[i].setWindow(controlWindow);
    }


    //p1.setWindow(controlWindow);
    //p2.setWindow(controlWindow);

    ///////////////////////////////////////////////////////////////////////////
    // Sonic matrix
    ///////////////////////////////////////////////////////////////////////////
    int matrix_sonic_xpos = 300;
    int matrix_sonic_ypos = 40;
    int matrix_sonic_entry_width = 44;
    int matrix_sonic_entry_height = 20;

    cp5_matrix_sonic = controlP5.addMatrix("matrix_sonic",matrix_sonic_nx,matrix_sonic_ny, matrix_sonic_xpos, matrix_sonic_ypos, matrix_sonic_entry_width*matrix_sonic_nx, matrix_sonic_entry_height*matrix_sonic_ny);
    //cp5_matrix_sonic.setInterval(1000);
    cp5_matrix_sonic.setLabel("testing");
    cp5_matrix_sonic.setLabelVisible(true);
    cp5_matrix_sonic.setWindow(controlWindow);

    for(int i=0;i<matrix_sonic_nx;i++)
    {
        String mylabel = "text_label_sonic_x_"+i;
        cp5_tl_sonic_x[i] = controlP5.addTextlabel(mylabel,sonic_labels[i],matrix_sonic_xpos+matrix_sonic_entry_width*i,matrix_sonic_ypos-10);
        cp5_tl_sonic_x[i].setColorValue(color(255));
        cp5_tl_sonic_x[i].setColorBackground(int(color(255,0,0)));
        cp5_tl_sonic_x[i].setWindow(controlWindow);
    }

    for(int i=0;i<matrix_sonic_ny;i++)
    {
        String mylabel = "text_label_sonic_y_"+i;
        cp5_tl_sonic_y[i] = controlP5.addTextlabel(mylabel,val_name[i],matrix_sonic_xpos+(matrix_sonic_nx*matrix_sonic_entry_width)+10,matrix_sonic_ypos+4+(i*matrix_sonic_entry_height));
        cp5_tl_sonic_y[i].setColorBackground(color(0));
        cp5_tl_sonic_y[i].setWindow(controlWindow);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////



    //dd_sonic_0 = controlP5.addDropdownList("dd_sonic_0",10,100,80,80);
    //customize_dd_sonic(dd_sonic_0,0);
    //dd_sonic = new DropdownList[4];
    //for (int i=0;i<4;i++)
    //{
    //String name = "dd_sonic_" + i;
    //dd_sonic[i] = controlP5.addDropdownList(name,10,80+20*i,80,80);
    //customize_dd_sonic(dd_sonic[i],i);
    //}

    cp5_button_play = controlP5.addButton("Play",0,10,30,50,19);
    cp5_button_stop = controlP5.addButton("Stop",0,80,30,50,19);
    cp5_button_pause = controlP5.addButton("Pause",0,150,30,50,19);

    cp5_button_play.setWindow(controlWindow);
    cp5_button_stop.setWindow(controlWindow);
    cp5_button_pause.setWindow(controlWindow);

    // Mute or blind
    //controlP5.addButton("Mute",0,650,30,50,19);
    //checkbox = controlP5.addCheckBox("checkBox",650,30);  
    //checkbox.addItem("Mute",0);
    //checkbox.addItem("Blind",1);

    cp5_toggle_mute = controlP5.addToggle("toggle_mute",false,20,300,10,10);
    cp5_toggle_mute.setLabel("Mute");
    cp5_toggle_mute.setWindow(controlWindow);

    cp5_toggle_blind = controlP5.addToggle("toggle_blind",false,20,330,10,10);
    cp5_toggle_blind.setLabel("Blind");
    cp5_toggle_blind.setWindow(controlWindow);

    Controller cp5_tempo_slider = controlP5.addSlider("Tempo",0,480,tempo,20,140,10,100);
    cp5_tempo_slider.setWindow(controlWindow);

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

    if (draw_background)
    {
        background(0);
    }
    //lights();

    // Set up some different colored lights
    pointLight(51, 102, 255, 65, 60, 100);
    pointLight(200, 40, 60, -65, -60, -150);
    // Raise overall light in scene
    //ambientLight(70, 70, 10);

    //lights();

    //directionalLight(126, 126, 126, 0, 0, -1);
    //ambientLight(102, 102, 102);
    ambientLight(126, 126, 126);

    ///////////////////////////////////////////////////////////////////////////
    // Draw beams
    ///////////////////////////////////////////////////////////////////////////
    // Beam pipe
    stroke(255,255,255,60);
    strokeWeight(4);
    line(xcenter,ycenter,20, xcenter,ycenter,screen_depth);
    noStroke();

    //if (true)
    if (!collision_occurred)
    {
        fill(0,255,0);
        //float beam_z = event_time - 500;
        //float beam_z = event_time;
        for (int j=0;j<2;j++)
        {
            if(j==0) 
            {
                fill(0,255,0);
                beam_z[j][0] = event_time;
            }
            else 
            {
                beam_z[j][0] = screen_depth - event_time;
                fill(255,0,0);
            }
            for (int i=0;i<5;i++)
            {

                pushMatrix();
                translate(beam_x[j][i], beam_y[j][i], beam_z[j][0] + beam_z_offset[j][i]); // Propagate along the z-axis
                sphere(4);
                popMatrix();
            }
        }

        event_time += 20;
        if (beam_z[1][0]<=-400)
        {
            for (int j=0;j<2;j++)
            {
                for (int i=0;i<10;i++)
                {
                    beam_x[j][i] = random(beam_size) - beam_size_half + xcenter_f;
                    beam_y[j][i] = random(beam_size) - beam_size_half + ycenter_f;
                    beam_z_offset[j][i] = random(beam_size) - beam_size_half;
                }
            }
            event_time = 0;
        }
    }

    // Check to see if a collision has occurred
    //if (abs(beam_z[1][0]-zcenter)<beam_size)
    //{
    //collision_occurred = true;
    //}
    //else
    //{
    //collision_occurred = false;
    //}
    ///////////////////////////////////////////////////////////////////////////

    for (int i=0;i<nitems;i++)
    {
        //fill(255,255,0);
        fill(colors[i][0],colors[i][1],colors[i][2]);
        pushMatrix();
        //println("pos: " + positions[i][0] + " " + positions[i][1] + " " + positions[i][2]);
        translate(positions[i][0],positions[i][1],positions[i][2]);
        if (!dont_show_graphics)
        {
            if (detector_flag[i]==0)
            {
                sphereDetail(6);
                sphere(5);
            }
            else if (detector_flag[i]==1)
            {
                box(20);
            }
        }
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
        boolean found_start_of_event = false;
        while (!found_start_of_event)
        {
            try{
                line = reader.readLine();
                println(line);
                num_sound_events = int(line);
                println("num_sound_events: " + num_sound_events);
                if (num_sound_events>0)
                {   
                    found_start_of_event = true;
                }
            }
            catch (Exception e)
            {
                e.printStackTrace();
                exit();
            }
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

        int callbackID = 1;
        for (int i = 0; i < num_sound_events; i++) 
        {
            // Read in a line
            try
            {
                line = reader.readLine();
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }

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
                float tracknum = norm_vals[((MyInt)pvals.get("tracknum")).getVal()];
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

                //println("xyz: "+xpos+" "+ypos+" "+zpos);

                ////////////////////////////////////////////////////////////////////
                // Map onto the sonic characteristics.
                ////////////////////////////////////////////////////////////////////

                //volume = volume_range*energy;
                //println(pmag);
                volume = volume_range*(pmag-0.8)*9.0;
                //println("pmag/volume: " + pmag + " " + volume);

                if (sound_mapping==0)
                {
                    //println("tracknum: "+tracknum);
                    pitch = 40 + 3*tracknum;
                    volume = 100;
                    duration = 2.0;
                }
                else if (sound_mapping==1)
                {
                    pitch = pitch_range*(radius/2.0) + z*40 + 20;
                    if (pitch>126) pitch = 126;
                }
                else if (sound_mapping==2)
                {
                    pitch = pitch_range* (1.0 - exp(-0.7*pmag));
                    //println("pitch: " + pitch + " " + pitch_range + " " + pmag);
                }
                else if (sound_mapping==3)
                {
                    //pitch = pitch_range*pmag;
                    pitch = pitch_range*(pmag-0.80)*6.0;
                    //println("pitch: " + pitch + " " + pitch_range + " " + pmag);
                }

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

                duration = 2.0;

                ///////////////////////////////////////////////////////////////////
                boolean found_time = false;
                for (int j=0;j<num_times;j++)
                {
                    //println("Searching --- " + time_steps[j]);
                    if (time_steps[j] == note_time)
                    {
                        //println(note_time);
                        int npos = int(xpositions[j][0])+1;
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
                ///////////////////////////////////////////////////////////////////
                // Set the values based on the matrix settings if a mapping
                // is not selected.
                ///////////////////////////////////////////////////////////////////
                if (sound_mapping == -1)
                {
                    println("sonic_index: " + sonic_index[0]);
                    if(sonic_index[0]>=0)
                    {
                        pitch = pitch_range*norm_vals[sonic_index[0]];
                        if (sonic_index[0]==0)
                        {
                            pitch = 40 + 3*norm_vals[sonic_index[0]];
                        }
                    }
                    if(sonic_index[1]>=0)
                    {
                        duration = duration_range*norm_vals[sonic_index[1]];
                    }
                    if(sonic_index[2]>=0)
                    {
                        volume = volume_range*norm_vals[sonic_index[2]];
                    }
                    //if(sonic_index[3]>=0)
                    //{
                    //instrument = instrument_range*norm_vals[sonic_index[3]];
                    //}
                }



                ///////////////////////////////////////////////////////////////////
                ///////////////////////////////////////////////////////////////////
                //println(note_time + " " + channel + " " + instrument + " " + pitch + " " + volume + " " + duration + " " + articulation + " " + pan);
                if (set_volume_to_0) { volume = 0; }
                score.addNote(note_time, channel, instrument, pitch, volume, duration, articulation, pan);
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

        //note_time+=10;
        note_time=max_note_time + 10;
        //println("ELSE note_time: " + note_time);
        score.addCallback(note_time, 0);

        println("Playing something!!!!!!!!!! --------------------- ");

        //draw_background = false;
        process_file = false;
        //background(0);
        //String outname = "BpBm_events_mapping" + sound_mapping + "/event_" + event_count + ".mid";
        //String outname = "tauptaum_events_mapping" + sound_mapping + "/event_" + event_count + ".mid";
        //println("Saving as: " + outname);
        //score.writeMidiFile(outname);

        //if (collision_occurred)
        //{
        collision_occurred = true;
        score.play();
        //}

        println("PLAYING!");
        event_count++;

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
            collision_occurred = false;
            makeMusic();
            //collision_occurred = false;
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
                //println("post xyz: "+positions[nitems][0]+" "+positions[nitems][1]+" "+positions[nitems][2]);

                if (sizes[time_index][j]<20) 
                { 
                    colors[nitems][0] = 155;
                    colors[nitems][1] = 210;
                    colors[nitems][2] = 255;
                    detector_flag[nitems] = 0;
                }
                else if (sizes[time_index][j]>=20) 
                { 

                    colors[nitems][0] = 255;
                    colors[nitems][1] = 255;
                    colors[nitems][2] = 0;
                    detector_flag[nitems] = 1;
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
void customize_rb_pick_physics(RadioButton rb) {

    for (int i=0;i<10;i++)
    {
        String theName = "rb_pick_physics" + i;
        int theValue = i;
        Toggle t = rb.addItem(theName,theValue);
        t.captionLabel().setColorBackground(color(80));
        t.captionLabel().style().movePadding(2,0,-1,2);
        t.captionLabel().style().moveMargin(-2,0,0,-3);
        t.captionLabel().style().backgroundWidth = 46;
    }

}
///////////////////////////////////////////////////////////////////////////////
void customize_multilist_mapping(MultiList ml) {
    MultiListButton b;
    b = ml.add("Choose a mapping",1);
    b.setId(-3);

    // Make some drop down items
    int nfiles = filenames.length;
    for(int i=0;i<nfiles;i++) {
        MultiListButton c = b.add("multilist_button_mapping"+i,20+i+1);
        c.setLabel("Mapping "+i);
        c.setColorBackground(color(64 + 18*i,0,0));
        c.setId(i);
    }

}
///////////////////////////////////////////////////////////////////////////////
void customize_multilist_files(MultiList ml) {
    MultiListButton b;
    b = ml.add("Choose a file",1);
    b.setId(-2);

    // Make some drop down items
    int nfiles = filenames.length;
    for(int i=0;i<nfiles;i++) {
        MultiListButton c = b.add("multilist_files_button_"+i,20+i+1);
        c.setLabel(filenames[i]);
        c.setColorBackground(color(64 + 18*i,0,0));
        c.setId(i);
    }

}
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
    //int num_mapping = 6;
    for(int i=0;i<num_mapping;i++) {
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
    draw_background = true;
    //myColor = theValue;
    if (selected_a_file)
    {
        background(0);
        redraw();
        process_file = true;
        //draw_background = true;
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
    draw_background = false;
    process_file = false;
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
public void Mute(int theValue) {
    println("a button event from Mute: "+theValue);

    set_volume_to_0 = true;
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
        println(theEvent.controller().id()+" from "+theEvent.controller());
        println("b");
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
        // Clear out the other settings
        for (int i=0;i<4;i++)
        {
            cp5_matrix_sonic.set(i,sonic_index[i],false);
            sonic_index[i] = -1;
        }
        //sonic_index = -1;
        //sonic_map_index = -1;
    }
    //else if (event_name == "multilist_files_button")
    else if (event_name.charAt(0)=='p' && event_name.charAt(1)=='i' &&
            event_name.charAt(2)=='c' && event_name.charAt(3)=='k'
            )
    {
        println("Here is a pick" + event_name);
        int index = int(theEvent.controller().id());
        println("b index: " + index);
        if (index>=0)
        {
            infile = pick_filenames[index];
            reader = createReader(infile);
            //process_file = true;
            selected_a_file = true;
            event_count = 0;
        }
        for (int i=0;i<num_physics;i++)
        {
            cp5_b_pick_physics[i].setColorBackground(color(button_color_off));
        }
        cp5_b_pick_physics[index].setColorBackground(color(button_color_on));
        //controlWindow.update();
        //controlWindow.updateEvents();
    }
    else if (event_name.charAt(0)=='m' && event_name.charAt(1)=='a' &&
            event_name.charAt(8)=='p' && event_name.charAt(9)=='i' &&
            event_name.charAt(10)=='c' && event_name.charAt(11)=='k'
            )
    {
        println("Here is a mapping pick from mapping_pick_" + event_name);
        int index = int(theEvent.controller().id());
        println("a index: -------------------------- " + index);
        if (index>=0)
        {
            // Clear out the matrix settings
            for (int i=0;i<4;i++)
            {
                for(int j=0;j<matrix_sonic_ny;j++)
                {
                    cp5_matrix_sonic.set(i,j,false);
                }
                sonic_index[i] = -1;
            }

            sound_mapping = index;
        }
        for (int i=0;i<num_mapping;i++)
        {
            cp5_b_pick_mapping[i].setColorBackground(color(mapping_button_color_off));
        }
        cp5_b_pick_mapping[index].setColorBackground(color(button_color_on));
    }
    //else if (event_name == "multilist_files_button")
    else if (event_name.charAt(0)=='m' && event_name.charAt(1)=='u' &&
            event_name.charAt(2)=='l' && event_name.charAt(3)=='t' &&
            event_name.charAt(16)=='b' && event_name.charAt(17)=='u' &&
            event_name.charAt(18)=='t' && event_name.charAt(19)=='t'
            )
    {
        int index = int(theEvent.controller().id());
        if (index>=0)
        {
            infile = filenames[index];
            reader = createReader(infile);
            //process_file = true;
            selected_a_file = true;
            event_count = 0;
        }
        //controlWindow.update();
        //controlWindow.updateEvents();
    }
    else if (event_name == "checkBox")
    {
        //int index = int(theEvent.group().value());
        int mute_flag = int(theEvent.group().arrayValue()[0]);
        int blind_flag = int(theEvent.group().arrayValue()[1]);
        println("mute_flag: "+mute_flag);
        println("blind_flag: "+blind_flag);
        if (mute_flag==1) { set_volume_to_0 = true; }
        else if (mute_flag==0) { set_volume_to_0 = false; }
        if (blind_flag==1) { dont_show_graphics = true; }
        else if (blind_flag==0) { dont_show_graphics = false; }
    }
    // Process the events from the dd_sonic_X dropdown menus.
    else if (event_name == "matrix_sonic")
    {
        int temp_x = cp5_matrix_sonic.getX(theEvent.controller().value());
        int temp_y = cp5_matrix_sonic.getY(theEvent.controller().value());
        sonic_index[temp_x] = temp_y;
        //sonic_map_index = cp5_matrix_sonic.getY(theEvent.controller().value());

        println("sonic_index: " + temp_x + "\tsonic_index val: " + temp_y);
        sound_mapping = -1;
        // Clear out the preset mappings
        for (int i=0;i<num_mapping;i++)
        {
            cp5_b_pick_mapping[i].setColorBackground(color(mapping_button_color_off));
        }
    }
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
/*
   void keyPressed() {
   println(char(1)+" / "+keyCode);
   if(key==' '){
   checkbox.deactivateAll();
   } else {
   for(int i=0;i<6;i++) {
// check if key 0-5 have been pressed and toggle
// the checkbox item accordingly.
if(keyCode==(48 + i)) { 
// the index of checkbox items start at 0
checkbox.toggle(i);
println("toggle "+checkbox.getItem(i).name());
// also see 
// checkbox.activate(index);
// checkbox.deactivate(index);
}
if (keyCode==0)
{
set_volume_to_0 = true;
}
}
}
}
 */
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

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void toggle_mute(boolean theFlag) {
    if(theFlag==true) {
        set_volume_to_0 = true;
    } else {
        set_volume_to_0 = false;
    }
    println("a toggle event.");
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void toggle_blind(boolean theFlag) {
    if(theFlag==true) {
        dont_show_graphics = true;
    } else {
        dont_show_graphics = false;
    }
    println("a toggle event.");
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


