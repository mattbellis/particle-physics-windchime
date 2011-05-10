/**
 * Example of how MIDI events can be sent directly, or scheduled in a score.
 * The program assumes you have an external MIDI device and you may need to
 * change the channel and controller number settings for your device.
 * Unusually, the callbackID is used as a data value for the controller.
 *
 * A SoundCipher example by Andrew R. Brown
 */

import arb.soundcipher.*;

///////////////////////////////////////////////////////////////////////////////
// GUI stuff
///////////////////////////////////////////////////////////////////////////////
import controlP5.*;

ControlP5 controlP5;

CheckBox checkbox;
///////////////////////////////////////////////////////////////////////////////


SoundCipher sc = new SoundCipher(this);
SCScore score;
float channel = 0;
float controller = 81;

float instruments[] = {SCScore.PIANO, SCScore.ACOUSTIC_GUITAR, SCScore.CELLO, SCScore.TIMPANI, SCScore.SAXOPHONE, SCScore.FRENCH_HORN, SCScore.DOUBLE_BASS, SCScore.OCARINA};

int musical_scale_range = 100;
float volume_range = 100;
float note_time_range = 60.0;
float duration_range = 10.0;
float pitch_range = 127;
float pan_range = 127;

int num_notes = 6;
int max_notes = 0; // counter

int screen_width = 600;
int screen_height = 600;

int background_color = 0;
int tempo = 120;

float[] random_pitch = new float[num_notes];
float[][] ell_vals = new float[num_notes][4];

boolean map_pitch_onto_ypos = false;
boolean reverse_ypos = false;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void setup() 
{
    size(screen_width,screen_height);
    background(background_color);
    //frameRate(1);
    frameRate(30);
    noStroke();
    smooth();

    score = new SCScore();
    score.addCallbackListener(this);
    score.tempo(tempo);

    ///////////////////////////////////////////////////////////////////////////
    // Draw all the GUI stuff.
    ///////////////////////////////////////////////////////////////////////////
    controlP5 = new ControlP5(this);
    controlP5.setAutoDraw(false);
    checkbox = controlP5.addCheckBox("checkBox",100,30);
    checkbox.addItem("Toggle",0);
    checkbox.addItem("Flip",1);
    controlP5.addButton("Play",0,10,30,50,19);
    controlP5.addButton("Stop",0,10,60,50,19);


    hint(ENABLE_NATIVE_FONTS);

    //makeMusic();

}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void draw() {
    background(0);
    //println(max_notes);
    for(int i=0;i<max_notes;i++)
    {
        fill(255,105,180,80);
        ellipse(ell_vals[i][0],ell_vals[i][1],ell_vals[i][2],ell_vals[i][3]);
    }
    controlP5.draw();

}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void makeMusic() {
    //background(0);
    //fill(255,20);
    fill(255,193,193,50);
    score.empty();
    //noStroke();
    //ellipse(random(800),random(800),random(100),random(100));


    float prev_time = 0.0;
    float now_time = 0.0;
    for (int i=0;i<num_notes;i++)
    {
        if (i!=0)
        {
            //now_time = random(3.0)+prev_time;
            now_time = 1.0+prev_time;
        }
        prev_time = now_time;
        //score.addNote(note_time, channel, instrument, pitch, volume, duration, articulation, pan);
        random_pitch[i] = random(60)+40;
        //score.addNote(now_time, channel, SCScore.PIANO, random(60)+30, 100, random(6.0), 1.0, 64);
        score.addNote(now_time, channel, SCScore.PIANO, random_pitch[i], 100, random(6.0), 1.0, 64);
        score.addCallback(now_time, i+1);
    }

    score.addCallback(now_time+10, 0);
    score.play();

}
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
void stop() {
    score.stop();
}
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void handleCallbacks(int callbackID) {
    switch (callbackID) {
        case 0:
            //while (score.isPlaying()) {};
            score.stop();
            max_notes = 0;
            background(background_color);
            makeMusic();
            break;

        default:

            int i = callbackID-1;
            //println(i);
            ell_vals[i][0] = random(screen_width-50)+50;
            if (map_pitch_onto_ypos)
            {
                ell_vals[i][1] = screen_height - (screen_height*(random_pitch[i] - 40)/60.0);
                if (reverse_ypos)
                {
                    ell_vals[i][1] = screen_height - ell_vals[i][1];
                }
            }
            else
            {
                ell_vals[i][1] = random(screen_height-50)+50;
            }
            //println("xy: "+ell_vals[i][0]+" "+ell_vals[i][1]);
            ell_vals[i][2] = random(50)+50;
            ell_vals[i][3] = random(50)+50;
            max_notes++;
            redraw();
    }
}



///////////////////////////////////////////////////////////////////////////////
void controlEvent(ControlEvent theEvent)
{
    // A controlEvent will be triggered from within the ControlGroup.
    // therefore you need to check the originator of the Event with
    // if (theEvent.isGroup())
    // to avoid an error message from controlP5.
    String event_name = theEvent.name();

    if (event_name == "checkBox")
    {
        //int index = int(theEvent.group().value());
        int toggle_flag = int(theEvent.group().arrayValue()[0]);
        int flip_flag = int(theEvent.group().arrayValue()[1]);
        println("toggle_flag: "+toggle_flag);
        println("flip_flag: "+flip_flag);
        if (toggle_flag==1) { map_pitch_onto_ypos = true; }
        else if (toggle_flag==0) { map_pitch_onto_ypos = false; }
        if (flip_flag==1) { reverse_ypos = true; }
        else if (flip_flag==0) { reverse_ypos = false; }
    }
    else if (event_name == "Play")
    {
        println("Play!");
        makeMusic();
        max_notes = 0;
    }
    else if (event_name == "Stop")
    {
        println("Stop!");
        score.stop();
    }
}


