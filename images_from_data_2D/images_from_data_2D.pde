/**
 * Example of how MIDI events can be sent directly, or scheduled in a score.
 * The program assumes you have an external MIDI device and you may need to
 * change the channel and controller number settings for your device.
 * Unusually, the callbackID is used as a data value for the controller.
 *
 * A SoundCipher example by Andrew R. Brown
 */

import arb.soundcipher.*;

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

int ievent = 0;

float xpos;
float ypos;

int num_times = 0;

float[] random_pitch = new float[500];
float[] ell_vals = new float[4];

float[] time_steps = new float[127];
float[][] xpositions = new float[127][500];
float[][] ypositions = new float[127][500];

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void setup()
{
    size(screen_width,screen_height);
    background(background_color);
    //frameRate(1);
    frameRate(60);
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
    lines = loadStrings("events_1237_10.txt");
    //lines = loadStrings("events_3429_10.txt");
    //lines = loadStrings("events_mupmum_CM_10.txt");
    //lines = loadStrings("events_bbbar_CM_1.txt");
    //lines = loadStrings("events_3429_1.txt");


    score = new SCScore();
    score.addCallbackListener(this);
    score.tempo(tempo);

    makeMusic();

}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void draw() {
    //ellipse(ell_vals[0],ell_vals[1],ell_vals[2],ell_vals[3]);
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void makeMusic() 
{
    //fill(255,193,193,50);
    fill(255,193,193);
    score.empty();

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

    String[] vals = split(lines[ievent], ' ');
    ievent++;

    int nentries = int(vals[0]);
    println("nentries: " + nentries);

    int max = nentries;
    //max = 125;
    //max = 300;
    int callbackID = 1;
    //for (int i = ievent; i < max; i++) 
    for (int i = 1; i <= max; i++) 
    {
        vals = split(lines[ievent], ' ');
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
            println("i note_time/pitch: " + i + " " + note_time + " " + pitch);

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
                //println("Adding " + note_time);
                time_steps[num_times] = note_time;
                xpositions[num_times][1] = xpos;
                ypositions[num_times][1] = ypos;
                xpositions[num_times][0] = 1;
                ypositions[num_times][0] = 1;
                num_times++;
            }
            ///////////////////////////////////////////////////////////////////

            //pitch += random(30);
            //pitch = 60;
            volume = 100;
            score.addNote(note_time, channel, instrument, pitch, volume, duration, articulation, pan);
            //int id = i+1;
            //id = id%200 + 1;
            //println("i+1: " + id);
            //score.addCallback(note_time, id);
            // callbackID seems to need to be less than 127!!!! ???
            if (!found_time)
            {
                score.addCallback(note_time, callbackID);
                callbackID++;
            }
            // The integer here (callbackID) has to be less than 256!
            //score.addCallback(note_time, 1);

        }
        ievent++;

    }

    for (int j=0;j<num_times;j++)
    {
        println("time_steps/xpositions: " + time_steps[j] + " " + xpositions[j][0]);
    }

    //note_time+=10;
    note_time=max_note_time + 2;
    println("ELSE note_time: " + note_time);
    score.addCallback(note_time, 0);

    println("Playing something!!!!!!!!!! --------------------- ");

    score.play();
    //score.writeMidiFile("my_test.mid");

    println("PLAYING!");

    //exit();

    // Set up for a new event/score.

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
    println("callbackID: " + int(callbackID));
    switch (callbackID) {
        case 0:
            //while (score.isPlaying()) {};
            score.stop();
            background(background_color);
            println("About to makeMusic from case 0");
            makeMusic();
            println("Just did makeMusic from case 0");
            break;

        default:

            ell_vals[0] = xpositions[callbackID][1];
            ell_vals[1] = ypositions[callbackID][1];
            //println(xpos[callbackID] + " " + ypos[callbackID]);
            //println(ell_vals[0] + " " + ell_vals[1]);

            //ell_vals[0] = random(screen_width-20)+20;
            //ell_vals[1] = random(screen_height-20)+20;
            //println(6.0*random_pitch[callbackID-1]);
            //ell_vals[1] = screen_height - (screen_height*(random_pitch[callbackID-1] - 40)/60.0);
            ell_vals[2] = random(10)+10;
            ell_vals[3] = random(10)+10;

            int npoints = int(xpositions[callbackID][0]);
            for (int j=1;j<npoints+1;j++)
            {
                float x = xpositions[callbackID][j];
                float y = ypositions[callbackID][j];
                float t = time_steps[callbackID];

                float r = sqrt(x*x+y*y);
                //println("r: " + r);

                //fill(55,93+(5*t),93);
                fill(155,10+r/3.0,93+r/3.0);
                //if (t>2.0)
                //{
                    //fill(55,93+(2*t),93);
                //}
                println("In callback t/x/y: "+t+" "+x+" "+y);
                ellipse(x, y, 3+t, 3+t);
            }

            redraw();
    }
}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////



