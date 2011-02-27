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

float instruments[] = {SCScore.PIANO, SCScore.ACOUSTIC_GUITAR, SCScore.CELLO, SCScore.TIMPANI, SCScore.SAXOPHONE, SCScore.FRENCH_HORN, SCScore.DOUBLE_BASS, SCScore.OCARINA};

int musical_scale_range = 100;
float volume_range = 100;
float note_time_range = 60.0;
float duration_range = 10.0;
float pitch_range = 127;
float pan_range = 127;

int screen_width = 600;
int screen_height = 600;

int background_color = 0;
int tempo = 210;

float[] random_pitch = new float[22];
float[] ell_vals = new float[4];

void setup() 
{
    size(screen_width,screen_height);
    background(background_color);
    //frameRate(1);
    frameRate(60);
    smooth();

    //sc.getMidiDeviceInfo();
    //sc.setMidiDeviceOutput(1);

    score = new SCScore();
    score.addCallbackListener(this);
    score.tempo(tempo);

    makeMusic();

}

void draw() {
    ellipse(ell_vals[0],ell_vals[1],ell_vals[2],ell_vals[3]);
}

void makeMusic() {
    //background(0);
    //fill(255,20);
    fill(255,193,193,50);
    score.empty();
    //noStroke();
    //ellipse(random(800),random(800),random(100),random(100));


    float prev_time = 0.0;
    float now_time = 0.0;
    for (int i=0;i<22;i++)
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


void stop() {
    score.stop();
}

void handleCallbacks(int callbackID) {
    switch (callbackID) {
        case 0:
            //while (score.isPlaying()) {};
            score.stop();
            background(background_color);
            makeMusic();
            break;

        default:

            ell_vals[0] = random(screen_width-20)+20;
            //ell_vals[1] = random(screen_height-20)+20;
            println(6.0*random_pitch[callbackID-1]);
            ell_vals[1] = screen_height - (screen_height*(random_pitch[callbackID-1] - 40)/60.0);
            ell_vals[2] = random(50)+50;
            ell_vals[3] = random(50)+50;
            redraw();
    }
}

