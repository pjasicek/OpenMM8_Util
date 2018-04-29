namespace ColorRemover
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.SelectFolder = new System.Windows.Forms.Button();
            this.folderPathTextbox = new System.Windows.Forms.TextBox();
            this.progressBar1 = new System.Windows.Forms.ProgressBar();
            this.label1 = new System.Windows.Forms.Label();
            this.GO = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // SelectFolder
            // 
            this.SelectFolder.Location = new System.Drawing.Point(200, 40);
            this.SelectFolder.Name = "SelectFolder";
            this.SelectFolder.Size = new System.Drawing.Size(34, 20);
            this.SelectFolder.TabIndex = 0;
            this.SelectFolder.Text = "...";
            this.SelectFolder.UseVisualStyleBackColor = true;
            this.SelectFolder.Click += new System.EventHandler(this.SelectFolder_Click);
            // 
            // folderPathTextbox
            // 
            this.folderPathTextbox.Location = new System.Drawing.Point(35, 40);
            this.folderPathTextbox.Name = "folderPathTextbox";
            this.folderPathTextbox.Size = new System.Drawing.Size(149, 20);
            this.folderPathTextbox.TabIndex = 1;
            this.folderPathTextbox.TextChanged += new System.EventHandler(this.folderPathTextbox_TextChanged);
            // 
            // progressBar1
            // 
            this.progressBar1.Location = new System.Drawing.Point(35, 123);
            this.progressBar1.Name = "progressBar1";
            this.progressBar1.Size = new System.Drawing.Size(199, 23);
            this.progressBar1.TabIndex = 2;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(32, 20);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(142, 13);
            this.label1.TabIndex = 3;
            this.label1.Text = "Directory with images (.bmp):";
            // 
            // GO
            // 
            this.GO.Location = new System.Drawing.Point(35, 75);
            this.GO.Name = "GO";
            this.GO.Size = new System.Drawing.Size(199, 33);
            this.GO.TabIndex = 4;
            this.GO.Text = "GO";
            this.GO.UseVisualStyleBackColor = true;
            this.GO.Click += new System.EventHandler(this.GO_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(263, 173);
            this.Controls.Add(this.GO);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.progressBar1);
            this.Controls.Add(this.folderPathTextbox);
            this.Controls.Add(this.SelectFolder);
            this.Name = "Form1";
            this.Text = "Color Remover";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button SelectFolder;
        private System.Windows.Forms.TextBox folderPathTextbox;
        private System.Windows.Forms.ProgressBar progressBar1;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button GO;
    }
}

