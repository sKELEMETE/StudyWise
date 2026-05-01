import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const maxFileSizeBytes = 15 * 1024 * 1024
const allowedExtensions = new Set(["jpg", "jpeg", "png", "pdf", "txt", "md"])

function getMimeType(extension: string): string {
  const ext = extension.toLowerCase()

  if (ext === "jpg" || ext === "jpeg") return "image/jpeg"
  if (ext === "png") return "image/png"
  if (ext === "pdf") return "application/pdf"
  if (ext === "md") return "text/markdown"
  if (ext === "txt") return "text/plain"
  return "text/plain"
}

function requireSafeFolderName(folderName: FormDataEntryValue | null): string {
  if (typeof folderName !== "string") throw new Error("Missing folder name")

  const cleanName = folderName.trim()

  if (!cleanName) throw new Error("Missing folder name")
  if (cleanName.includes("/") || cleanName.includes("\\")) {
    throw new Error("Invalid folder name")
  }

  return cleanName
}

function requireSafeFileName(fileName: FormDataEntryValue | null): string {
  if (typeof fileName !== "string") throw new Error("Missing file name")

  const cleanName = fileName.split(/[\\/]/).pop()?.trim() ?? ""

  if (!cleanName) throw new Error("Missing file name")
  if (cleanName === "." || cleanName === "..") {
    throw new Error("Invalid file name")
  }

  return cleanName
}

function requireAllowedExtension(fileType: FormDataEntryValue | null): string {
  if (typeof fileType !== "string") throw new Error("Unsupported file type")

  const ext = fileType.toLowerCase().replace(/^\./, "")

  if (!allowedExtensions.has(ext)) {
    throw new Error("Unsupported file type")
  }

  return ext
}

function createSupabaseClient(req: Request) {
  const authHeader = req.headers.get("Authorization")

  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: authHeader ? { Authorization: authHeader } : {},
      },
      auth: {
        persistSession: false,
      }
    }
  )
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 405,
        },
      )
    }

    const supabase = createSupabaseClient(req)

    const authHeader = req.headers.get("Authorization")
    const token = authHeader ? authHeader.replace("Bearer ", "") : ""

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      throw new Error("Unauthorized user")
    }

    const formData = await req.formData()
    const file = formData.get("file")
    const folderName = requireSafeFolderName(formData.get("folderName"))
    const fileName = requireSafeFileName(formData.get("fileName"))
    const fileType = requireAllowedExtension(formData.get("fileType"))
    const extractedTextEntry = formData.get("extractedText")
    const extractedText = typeof extractedTextEntry === "string"
      ? extractedTextEntry.trim()
      : ""

    if (!(file instanceof File)) throw new Error("Missing file")
    if (file.size === 0) throw new Error("Missing file")
    if (file.size > maxFileSizeBytes) throw new Error("File is too large")
    if (!extractedText) throw new Error("No readable text found")

    const filePath = `${user.id}/${folderName}/${fileName}`
    const arrayBuffer = await file.arrayBuffer()

    const { error: uploadError } = await supabase.storage
      .from("StudyMaterials")
      .upload(filePath, arrayBuffer, {
        contentType: getMimeType(fileType),
        upsert: true,
      })

    if (uploadError) throw uploadError

    await supabase
      .from("study_materials")
      .delete()
      .eq("file_path", filePath)
      .eq("student_id", user.id)

    const { data, error: dbError } = await supabase
      .from("study_materials")
      .insert({
        file_type: fileType,
        raw_text: extractedText,
        file_path: filePath,
        student_id: user.id,
      })
      .select()

    if (dbError) throw dbError

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    })

  } catch (err) {
    const message = err instanceof Error ? err.message : "Upload failed"

    return new Response(
      JSON.stringify({ error: message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    )
  }
})
