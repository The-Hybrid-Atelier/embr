# Embr
Supplementary materials accompanying the CHI2022 publication:
__Embr: A Creative Framework for Hand Embroidered Liquid Crystal Textile Displays__

## Contributors

* Shreyosi Endow
* Cesar Torres

Code maintained by: Shreyosi Endow (shreyosi.endow@mavs.uta.edu)

# Embr Tool
## Live App
A live version of the Embr E-Stitchbook is available at:
* https://hybridatelier.uta.edu/apps/embr

## Local installation
The Embr application was developed as a Ruby on Rails application. To run, download and install ruby version >= 2.4.0. You will need to run initial Rails setup routines:
```
bundle install
rake db:migrate
```
The application server can then be run using:
```
rails server
```

Open a web browser (we recommend Chrome) and point it to: 
`localhost:3000`

## Troubleshooting

* mySQL not installing during `bundle install`? Try installing dependencies through brew: `brew install msql` then rerun `bundle install`.  
* Getting a SECRET_BASE warning? Run
`rake secret`
Copy and paste the generated hash into your bashrc file as follows:
`export MY_SECRET_BASE=<generated_hash>`
Restart your terminal for the changes to take effect.

# E-Stitchbook
The E-stitchbook (estitchbook.pdf) formally characterizes 12 electronic embroidery stitches and their corresponding liquid crystal expressions. For each stitch, we showcase the front and back of the stitch as rendered in the Embr tool, the physical and thermal results as well as the physical, thermal and electrical properties of the stitch. The estitchbook.pdf file can be opened using any pdf viewer.

# Video Figure and Video Figure Captions 
The video figure (Video-Figure.mp4) walks through the contributions of the Embr framework. The video showcases the different functionalities  of the Embr tool such as the stitch assembly view and heat simulation in action. Additionally the video demonstrates the color transitions of the LCTD exemplars which were not fully captured in the paper figures. Closed captions for spoken dialogue were generated and included in the Video-Figure-Captions.srt file. 

# Video Preview and Video Preview Captions
The video preview (Video-Preview.mp4) is a 30 second teaser of the Embr framework and aims to provide a glimpse of our contribution to the HCI community. The video contains no spoken dialogue and this information is included in the Video-Preview-Captions.srt captions file.

