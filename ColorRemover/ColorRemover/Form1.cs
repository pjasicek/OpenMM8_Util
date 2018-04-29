using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ColorRemover
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void SelectFolder_Click(object sender, EventArgs e)
        {
            using (var folderDialog = new FolderBrowserDialog())
            {
                if (folderDialog.ShowDialog() == DialogResult.OK)
                {
                    this.folderPathTextbox.Text = folderDialog.SelectedPath;
                }
            }
        }

        private void folderPathTextbox_TextChanged(object sender, EventArgs e)
        {

        }

        private void GO_Click(object sender, EventArgs e)
        {
            string[] bmpFiles = Directory.GetFiles(@"" + folderPathTextbox.Text, "*.bmp*", SearchOption.AllDirectories).ToArray();

            int numFiles = bmpFiles.Length;

            Console.WriteLine("Files: " + bmpFiles.ToString());
            Console.WriteLine("Num files. " + numFiles);
            Console.WriteLine("Path: " + folderPathTextbox.Text);

            string outDir = folderPathTextbox.Text + "\\ColorRemover";
            if (Directory.Exists(outDir))
            {
                Directory.Delete(outDir, true);
            }
            Directory.CreateDirectory(outDir);


            int fileIdx = 0;
            foreach (string file in bmpFiles)
            {
                Bitmap bmp = (Bitmap)Image.FromFile(file);
                
                //bmp.MakeTransparent(bmp.GetPixel(0, 0));
                bmp.MakeTransparent(Color.FromArgb(0, 252, 252));
                bmp.MakeTransparent(Color.FromArgb(0, 251, 252));
                bmp.MakeTransparent(Color.FromArgb(0, 252, 251));
                bmp.MakeTransparent(Color.FromArgb(0, 255, 255));
                bmp.MakeTransparent(Color.FromArgb(0, 254, 255));
                bmp.MakeTransparent(Color.FromArgb(252, 0, 252));
                bmp.MakeTransparent(Color.FromArgb(252, 252, 0));
                Image img = (Image)bmp;
                string fname = Path.GetFileNameWithoutExtension(file);
                img.Save(outDir + "\\" + fname + ".png", ImageFormat.Png);

                fileIdx++;
                progressBar1.Value = (fileIdx / numFiles) * 100;
                progressBar1.Refresh();
                Application.DoEvents();
            }
        }
    }
}
